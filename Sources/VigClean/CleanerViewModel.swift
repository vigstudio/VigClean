import Foundation
import SwiftUI

@MainActor
final class CleanerViewModel: ObservableObject {
    @Published private(set) var findings: [CleanupFinding] = []
    @Published var selectedIDs: Set<CleanupFinding.ID> = []
    @Published var selectedPathIDs: Set<CleanupPathEntry.ID> = []
    @Published var permanentlyDelete = false
    @Published var terminateAffectedApps = false
    @Published var requestAdminWhenNeeded = true
    @Published private(set) var isScanning = false
    @Published private(set) var isCleaning = false
    @Published private(set) var hasScannedClean = false
    @Published private(set) var hasScannedApps = false
    @Published private(set) var hasScannedDisk = false
    @Published private(set) var status = "Ready"
    @Published private(set) var progressDetail = ""
    @Published private(set) var operationProgress: Double?
    @Published private(set) var lastErrors: [String] = []
    @Published var filterText = ""
    @Published private(set) var installedApps: [InstalledApp] = []
    @Published private(set) var isScanningApps = false
    @Published var appFilterText = ""
    @Published var language: AppLanguage = .vietnamese
    @Published var includePrivacySensitiveScan = false
    @Published private(set) var isScanningDisk = false
    @Published private(set) var diskAnalysis: DiskAnalysisResult?
    @Published var selectedDiskItemIDs: Set<DiskUsageItem.ID> = []
    @Published private(set) var protectedPaths: Set<String> = []
    @Published private(set) var cleanupHistory: [CleanupHistoryEntry] = []
    @Published private var appPathSelections: [String: Set<CleanupPathEntry.ID>] = [:]

    private let protectedPathsKey = "VigClean.protectedPaths"
    private let cleanupHistoryKey = "VigClean.cleanupHistory"
    private var cleanupScanTask: Task<Void, Never>?
    private var appScanTask: Task<Void, Never>?
    private var diskScanTask: Task<Void, Never>?

    init() {
        protectedPaths = Set(UserDefaults.standard.stringArray(forKey: protectedPathsKey) ?? [])
        if let data = UserDefaults.standard.data(forKey: cleanupHistoryKey),
           let entries = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) {
            cleanupHistory = entries
        }
    }

    func t(_ key: String) -> String {
        L10n.text(key, language)
    }

    var selectedFindings: [CleanupFinding] {
        findings.compactMap { finding in
            let entries = finding.pathEntries
                .flatMap { minimalSelectedEntries($0, selectedIDs: selectedPathIDs) }
                .filter { cleanability(for: $0).isSelectable }
            guard !entries.isEmpty else { return nil }
            return finding.withPathEntries(entries)
        }
    }

    var visibleFindings: [CleanupFinding] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return findings }

        return findings.filter { finding in
            finding.title.localizedCaseInsensitiveContains(query)
                || finding.detail.localizedCaseInsensitiveContains(query)
                || finding.paths.contains { $0.path.localizedCaseInsensitiveContains(query) }
        }
    }

    var selectedBytes: Int64 {
        CleanupSelectionPlan(findings: selectedFindings).estimatedBytes
    }

    var selectedItemCount: Int {
        selectedFindings.reduce(0) { $0 + $1.pathEntries.count }
    }

    var selectedRiskCount: Int {
        selectedFindings.filter { $0.risk != .safe }.count
    }

    var totalBytes: Int64 {
        findings.reduce(Int64(0)) { $0 + $1.bytes }
    }

    var visibleApps: [InstalledApp] {
        let query = appFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return installedApps }

        return installedApps.filter { app in
            app.name.localizedCaseInsensitiveContains(query)
                || app.bundleID?.localizedCaseInsensitiveContains(query) == true
                || app.appURL.path.localizedCaseInsensitiveContains(query)
        }
    }

    var selectedDiskItems: [DiskUsageItem] {
        diskAnalysis?.items.flatMap { selectedDiskEntries($0) } ?? []
    }

    var selectedDiskBytes: Int64 {
        selectedDiskItems.reduce(Int64(0)) { $0 + $1.bytes }
    }

    func scan() {
        guard !isScanning, !isCleaning else { return }
        isScanning = true
        status = "Scanning..."
        progressDetail = "Preparing scan..."
        operationProgress = 0
        lastErrors = []

        cleanupScanTask = Task {
            let includePrivacySensitiveScan = includePrivacySensitiveScan
            let nextFindings = await CleanupScanner().scan(includePrivacySensitiveFolders: includePrivacySensitiveScan) { [weak self] message, fraction in
                self?.progressDetail = message
                self?.operationProgress = fraction
            }
            guard !Task.isCancelled else { return }
            findings = nextFindings
            selectedPathIDs = Set(
                nextFindings.filter(\.selectedByDefault)
                    .flatMap(\.pathEntries)
                    .flatMap(\.flattened)
                    .filter { cleanability(for: $0).isSelectable }
                    .map(\.id)
            )
            selectedIDs = Set(nextFindings.filter { finding in
                let selectable = finding.pathEntries.flatMap(\.flattened).filter { cleanability(for: $0).isSelectable }
                return finding.selectedByDefault && !selectable.isEmpty && selectable.allSatisfy { selectedPathIDs.contains($0.id) }
            }.map(\.id))
            status = nextFindings.isEmpty ? "No cleanup targets found" : "Found \(nextFindings.count) cleanup targets"
            progressDetail = "Scan complete"
            hasScannedClean = true
            isScanning = false
            operationProgress = nil
        }
    }

    func scanApps() {
        guard !isScanningApps, !isCleaning else { return }
        isScanningApps = true
        status = "Scanning apps..."
        progressDetail = "Preparing app scan..."
        operationProgress = 0
        lastErrors = []

        appScanTask = Task {
            let apps = await CleanupScanner().scanInstalledApps { [weak self] message, fraction in
                self?.progressDetail = message
                self?.operationProgress = fraction
            }
            guard !Task.isCancelled else { return }
            installedApps = apps
            status = apps.isEmpty ? "No installed apps found" : "Found \(apps.count) installed apps"
            progressDetail = "App scan complete"
            hasScannedApps = true
            isScanningApps = false
            operationProgress = nil
        }
    }

    func analyzeDisk() {
        guard !isScanningDisk, !isCleaning else { return }
        isScanningDisk = true
        status = "Analyzing disk..."
        progressDetail = "Preparing disk analysis..."
        operationProgress = 0
        lastErrors = []

        diskScanTask = Task {
            let result = await DiskAnalyzer().analyze { [weak self] message, fraction in
                self?.progressDetail = message
                self?.operationProgress = fraction
            }
            guard !Task.isCancelled else { return }
            diskAnalysis = result
            selectedDiskItemIDs.removeAll()
            hasScannedDisk = true
            status = "Disk analysis complete"
            progressDetail = "\(result.volume.freeBytes.storageText) free of \(result.volume.totalBytes.storageText)"
            isScanningDisk = false
            operationProgress = nil
        }
    }

    func cancelCurrentScan() {
        cleanupScanTask?.cancel()
        appScanTask?.cancel()
        diskScanTask?.cancel()
        cleanupScanTask = nil
        appScanTask = nil
        diskScanTask = nil
        isScanning = false
        isScanningApps = false
        isScanningDisk = false
        operationProgress = nil
        status = "Scan cancelled"
        progressDetail = "No files were changed"
    }

    func cleanSelected() {
        guard !isScanning, !isCleaning, !selectedFindings.isEmpty else { return }
        let targets = selectedFindings
        isCleaning = true
        status = "Cleaning \(targets.count) selected targets..."
        progressDetail = "Deleting selected paths..."
        operationProgress = 0
        lastErrors = []

        let permanentlyDelete = permanentlyDelete
        let terminateAffectedApps = terminateAffectedApps
        let requestAdminWhenNeeded = requestAdminWhenNeeded
        let protectedPaths = protectedPaths
        let itemCount = targets.flatMap(\.pathEntries).count

        Task {
            let result = await Task.detached {
                await CleanupScanner().delete(
                    targets,
                    permanently: permanentlyDelete,
                    terminateAffectedApps: terminateAffectedApps,
                    requestAdminWhenNeeded: requestAdminWhenNeeded,
                    protectedPaths: protectedPaths,
                    progress: { [weak self] path, fraction in
                    self?.progressDetail = path
                    self?.operationProgress = fraction
                    }
                )
            }.value
            lastErrors = result.errors
            status = result.errors.isEmpty
                ? "Cleaned \(result.deletedBytes.storageText)"
                : "Cleaned \(result.deletedBytes.storageText), with \(result.errors.count) errors"
            progressDetail = "Clean complete"
            isCleaning = false
            operationProgress = nil
            recordHistory(CleanupHistoryEntry(
                kind: .cleanup,
                title: "Smart cleanup",
                deletedBytes: result.deletedBytes,
                recoveredBytes: result.recoveredBytes,
                freeBytesBefore: result.freeBytesBefore,
                freeBytesAfter: result.freeBytesAfter,
                itemCount: itemCount,
                errorCount: result.errors.count,
                permanent: permanentlyDelete
            ))
            if hasScannedClean {
                scan()
            }
        }
    }

    func uninstall(_ app: InstalledApp) {
        guard !isScanning, !isCleaning else { return }
        isCleaning = true
        status = "Uninstalling \(app.name)..."
        progressDetail = "Preparing uninstall paths..."
        operationProgress = 0
        lastErrors = []

        let entries = selectedEntries(for: app)
        guard !entries.isEmpty else {
            status = "No paths selected for \(app.name)"
            progressDetail = "Nothing was changed"
            operationProgress = nil
            isCleaning = false
            return
        }

        let finding = app.cleanupFinding.withPathEntries(entries)
        let permanentlyDelete = permanentlyDelete
        let requestAdminWhenNeeded = requestAdminWhenNeeded
        let protectedPaths = protectedPaths

        Task {
            let result = await Task.detached {
                await CleanupScanner().delete(
                    [finding],
                    permanently: permanentlyDelete,
                    terminateAffectedApps: true,
                    requestAdminWhenNeeded: requestAdminWhenNeeded,
                    protectedPaths: protectedPaths,
                    progress: { [weak self] path, fraction in
                        self?.progressDetail = path
                        self?.operationProgress = fraction
                    }
                )
            }.value
            lastErrors = result.errors
            status = result.errors.isEmpty
                ? "Uninstalled \(app.name), removed \(result.deletedBytes.storageText)"
                : "Uninstalled \(app.name) with \(result.errors.count) errors"
            progressDetail = "Uninstall complete"
            isCleaning = false
            operationProgress = nil
            recordHistory(CleanupHistoryEntry(
                kind: .uninstall,
                title: app.name,
                deletedBytes: result.deletedBytes,
                recoveredBytes: result.recoveredBytes,
                freeBytesBefore: result.freeBytesBefore,
                freeBytesAfter: result.freeBytesAfter,
                itemCount: entries.count,
                errorCount: result.errors.count,
                permanent: permanentlyDelete
            ))
            if hasScannedApps {
                scanApps()
            }
        }
    }

    func toggle(_ finding: CleanupFinding) {
        let ids = Set(finding.pathEntries.flatMap(\.flattened).filter { cleanability(for: $0).isSelectable }.map(\.id))
        if ids.isSubset(of: selectedPathIDs) {
            selectedIDs.remove(finding.id)
            selectedPathIDs.subtract(ids)
        } else {
            selectedIDs.insert(finding.id)
            selectedPathIDs.formUnion(ids)
        }
    }

    func togglePath(_ entry: CleanupPathEntry, in finding: CleanupFinding) {
        guard cleanability(for: entry).isSelectable else { return }
        let ids = Set(entry.flattened.filter { cleanability(for: $0).isSelectable }.map(\.id))
        if ids.isSubset(of: selectedPathIDs) {
            selectedPathIDs.subtract(ids)
        } else {
            selectedPathIDs.formUnion(ids)
        }

        normalizeParentSelection(in: finding.pathEntries, selectedIDs: &selectedPathIDs)
        let findingIDs = Set(finding.pathEntries.flatMap(\.flattened).filter { cleanability(for: $0).isSelectable }.map(\.id))
        if findingIDs.isSubset(of: selectedPathIDs) {
            selectedIDs.insert(finding.id)
        } else {
            selectedIDs.remove(finding.id)
        }
    }

    func isSelected(_ entry: CleanupPathEntry) -> Bool {
        let ids = Set(entry.flattened.filter { cleanability(for: $0).isSelectable }.map(\.id))
        return !ids.isEmpty && ids.isSubset(of: selectedPathIDs)
    }

    func isProtected(_ entry: CleanupPathEntry) -> Bool {
        isPathProtected(entry.url)
    }

    func cleanability(for entry: CleanupPathEntry) -> CleanupPathCleanability {
        if isProtected(entry) { return .protected }
        return entry.cleanability
    }

    func isPathProtected(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return protectedPaths.contains { protected in
            path == protected || path.hasPrefix(protected + "/")
        }
    }

    func toggleProtection(_ entry: CleanupPathEntry) {
        let path = entry.url.standardizedFileURL.path
        if protectedPaths.contains(path) {
            protectedPaths.remove(path)
        } else {
            protectedPaths.insert(path)
            selectedPathIDs.subtract(entry.flattened.map(\.id))
        }
        refreshFindingSelectionState()
        UserDefaults.standard.set(protectedPaths.sorted(), forKey: protectedPathsKey)
    }

    func removeProtectedPath(_ path: String) {
        protectedPaths.remove(path)
        UserDefaults.standard.set(protectedPaths.sorted(), forKey: protectedPathsKey)
    }

    func clearHistory() {
        cleanupHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: cleanupHistoryKey)
    }

    func selectAllSafe() {
        selectedIDs = Set(findings.filter { $0.risk != .personal }.map(\.id))
        selectedPathIDs = Set(
            findings
                .filter { $0.risk != .personal }
                .flatMap(\.pathEntries)
                .flatMap(\.flattened)
                .filter { cleanability(for: $0).isSelectable }
                .map(\.id)
        )
    }

    func clearSelection() {
        selectedIDs.removeAll()
        selectedPathIDs.removeAll()
    }

    private func refreshFindingSelectionState() {
        for finding in findings {
            let selectableIDs = Set(
                finding.pathEntries
                    .flatMap(\.flattened)
                    .filter { !isProtected($0) }
                    .map(\.id)
            )
            if selectableIDs.isEmpty || !selectableIDs.isSubset(of: selectedPathIDs) {
                selectedIDs.remove(finding.id)
            }
        }
    }

    func toggleDiskItem(_ item: DiskUsageItem) {
        let ids = Set(item.flattened.map(\.id))
        if ids.isSubset(of: selectedDiskItemIDs) {
            selectedDiskItemIDs.subtract(ids)
        } else {
            selectedDiskItemIDs.formUnion(ids)
        }
    }

    func isDiskItemSelected(_ item: DiskUsageItem) -> Bool {
        Set(item.flattened.map(\.id)).isSubset(of: selectedDiskItemIDs)
    }

    func deleteSelectedDiskItems() {
        guard !selectedDiskItems.isEmpty, !isCleaning else { return }
        isCleaning = true
        status = "Deleting disk analysis selections..."
        progressDetail = "Deleting \(selectedDiskItems.count) selected items..."
        operationProgress = 0
        lastErrors = []

        let findings = selectedDiskItems.map { item in
            CleanupFinding(
                title: item.title,
                detail: item.purpose,
                pathEntries: [
                    CleanupPathEntry(url: item.path, bytes: item.bytes, cleanability: .removable)
                ],
                bytes: item.bytes,
                risk: item.recommendation == .removable ? .review : .personal,
                selectedByDefault: false
            )
        }
        let permanentlyDelete = permanentlyDelete
        let terminateAffectedApps = terminateAffectedApps
        let requestAdminWhenNeeded = requestAdminWhenNeeded
        let protectedPaths = protectedPaths
        let itemCount = findings.count

        Task {
            let result = await Task.detached {
                await CleanupScanner().delete(
                    findings,
                    permanently: permanentlyDelete,
                    terminateAffectedApps: terminateAffectedApps,
                    requestAdminWhenNeeded: requestAdminWhenNeeded,
                    protectedPaths: protectedPaths,
                    progress: { [weak self] path, fraction in
                        self?.progressDetail = path
                        self?.operationProgress = fraction
                    }
                )
            }.value
            lastErrors = result.errors
            status = result.errors.isEmpty
                ? "Deleted \(result.deletedBytes.storageText)"
                : "Deleted \(result.deletedBytes.storageText), with \(result.errors.count) errors"
            progressDetail = "Disk cleanup complete"
            isCleaning = false
            operationProgress = nil
            recordHistory(CleanupHistoryEntry(
                kind: .diskCleanup,
                title: "Disk cleanup",
                deletedBytes: result.deletedBytes,
                recoveredBytes: result.recoveredBytes,
                freeBytesBefore: result.freeBytesBefore,
                freeBytesAfter: result.freeBytesAfter,
                itemCount: itemCount,
                errorCount: result.errors.count,
                permanent: permanentlyDelete
            ))
            analyzeDisk()
        }
    }

    func selectedEntries(for app: InstalledApp) -> [CleanupPathEntry] {
        let selected = appPathSelections[app.appURL.path] ?? Set(app.relatedEntries.flatMap(\.flattened).map(\.id))
        let entries = app.relatedEntries.flatMap { minimalSelectedEntries($0, selectedIDs: selected) }
            .filter { cleanability(for: $0).isSelectable }
        return CleanupSelectionPlan(entries: entries).entries
    }

    func isAppPathSelected(_ entry: CleanupPathEntry, app: InstalledApp) -> Bool {
        let selected = appPathSelections[app.appURL.path] ?? Set(app.relatedEntries.flatMap(\.flattened).map(\.id))
        return Set(entry.flattened.map(\.id)).isSubset(of: selected)
    }

    func toggleAppPath(_ entry: CleanupPathEntry, app: InstalledApp) {
        var selected = appPathSelections[app.appURL.path] ?? Set(app.relatedEntries.flatMap(\.flattened).map(\.id))
        let ids = Set(entry.flattened.map(\.id))
        if ids.isSubset(of: selected) {
            selected.subtract(ids)
        } else {
            selected.formUnion(ids)
        }
        normalizeParentSelection(in: app.relatedEntries, selectedIDs: &selected)
        appPathSelections[app.appURL.path] = selected
    }

    func selectedBytes(for app: InstalledApp) -> Int64 {
        selectedEntries(for: app).reduce(Int64(0)) { $0 + $1.bytes }
    }

    private func minimalSelectedEntries(_ entry: CleanupPathEntry, selectedIDs: Set<CleanupPathEntry.ID>) -> [CleanupPathEntry] {
        if selectedIDs.contains(entry.id) {
            return [entry.withoutChildren()]
        }

        return entry.children.flatMap { minimalSelectedEntries($0, selectedIDs: selectedIDs) }
    }

    private func normalizeParentSelection(in entries: [CleanupPathEntry], selectedIDs: inout Set<CleanupPathEntry.ID>) {
        for entry in entries where !entry.children.isEmpty {
            normalizeParentSelection(in: entry.children, selectedIDs: &selectedIDs)
            let childIDs = Set(entry.children.flatMap(\.flattened).map(\.id))
            if childIDs.isSubset(of: selectedIDs) {
                selectedIDs.insert(entry.id)
            } else {
                selectedIDs.remove(entry.id)
            }
        }
    }

    private func recordHistory(_ entry: CleanupHistoryEntry) {
        cleanupHistory.insert(entry, at: 0)
        cleanupHistory = Array(cleanupHistory.prefix(100))
        if let data = try? JSONEncoder().encode(cleanupHistory) {
            UserDefaults.standard.set(data, forKey: cleanupHistoryKey)
        }
    }

    private func selectedDiskEntries(_ item: DiskUsageItem) -> [DiskUsageItem] {
        if selectedDiskItemIDs.contains(item.id) {
            return [DiskUsageItem(
                title: item.title,
                path: item.path,
                bytes: item.bytes,
                purpose: item.purpose,
                recommendation: item.recommendation,
                lastAccessed: item.lastAccessed,
                children: []
            )]
        }

        return item.children.flatMap { selectedDiskEntries($0) }
    }
}

private extension CleanupFinding {
    func withPathEntries(_ entries: [CleanupPathEntry]) -> CleanupFinding {
        let plan = CleanupSelectionPlan(entries: entries)
        return CleanupFinding(
            title: title,
            detail: detail,
            pathEntries: plan.entries,
            bytes: plan.estimatedBytes,
            risk: risk,
            selectedByDefault: selectedByDefault
        )
    }
}

private extension CleanupPathEntry {
    func withoutChildren() -> CleanupPathEntry {
        CleanupPathEntry(url: url, bytes: bytes, cleanability: cleanability)
    }
}
