import Foundation

struct DiskAnalyzer: Sendable {
    private let home = FileManager.default.homeDirectoryForCurrentUser
    private var fileManager: FileManager { .default }

    func analyze(progress: @MainActor (String) -> Void = { _ in }) async -> DiskAnalysisResult {
        await progress("Reading disk capacity...")
        let volume = volumeSummary()

        await progress("Scanning user folders...")
        let userCategories = [
            category("Documents", detail: "User documents and Codex workspaces.", path: "~/Documents", color: "blue"),
            category("Downloads", detail: "Downloaded files and installers.", path: "~/Downloads", color: "orange"),
            category("Desktop", detail: "Desktop files.", path: "~/Desktop", color: "cyan"),
            category("Pictures", detail: "Photos and image libraries.", path: "~/Pictures", color: "pink"),
            category("Movies", detail: "Videos and screen recordings.", path: "~/Movies", color: "purple"),
            category("Music", detail: "Music libraries and audio files.", path: "~/Music", color: "mint")
        ].compactMap { $0 }
        await Task.yield()

        await progress("Scanning Library application data...")
        let libraryCategories = [
            category("Application Support", detail: "Per-app databases, local media, models, and support data.", path: "~/Library/Application Support", color: "green"),
            category("Containers", detail: "Sandboxed app containers.", path: "~/Library/Containers", color: "teal"),
            category("Group Containers", detail: "Shared app containers, often messaging and cloud app data.", path: "~/Library/Group Containers", color: "indigo"),
            category("Caches", detail: "Cache files that apps can usually recreate.", path: "~/Library/Caches", color: "yellow"),
            category("Developer", detail: "Xcode, simulator, SDK, and developer tool data.", path: "~/Library/Developer", color: "red")
        ].compactMap { $0 }
        await Task.yield()

        await progress("Finding largest folders...")
        let roots = [
            "~/Documents",
            "~/Downloads",
            "~/Developer",
            "~/Library/Application Support",
            "~/Library/Containers",
            "~/Library/Group Containers",
            "~/Library/Caches",
            "~/Library/Developer",
            "~/Library/Android"
        ]
        let items = roots.flatMap { largeChildren(under: $0, minimumBytes: 100 * 1024 * 1024) }
            .sorted { $0.bytes > $1.bytes }
            .prefix(80)
            .map { $0 }

        await progress("Disk analysis complete")
        return DiskAnalysisResult(
            volume: volume,
            categories: (userCategories + libraryCategories).sorted { $0.bytes > $1.bytes },
            items: items
        )
    }

    private func volumeSummary() -> DiskVolumeSummary {
        let values = try? home.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        let total = Int64(values?.volumeTotalCapacity ?? 0)
        let importantFree = values?.volumeAvailableCapacityForImportantUsage.map { Int64($0) }
        let availableFree = values?.volumeAvailableCapacity.map { Int64($0) }
        let free = importantFree ?? availableFree ?? 0

        return DiskVolumeSummary(totalBytes: total, freeBytes: free)
    }

    private func category(_ name: String, detail: String, path: String, color: String) -> DiskCategorySummary? {
        let url = expand(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let bytes = directorySize(url)
        guard bytes > 0 else { return nil }
        return DiskCategorySummary(name: name, detail: detail, bytes: bytes, colorName: color)
    }

    private func largeChildren(under root: String, minimumBytes: Int64) -> [DiskUsageItem] {
        let rootURL = expand(root)
        guard fileManager.fileExists(atPath: rootURL.path),
              let children = try? fileManager.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .contentAccessDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return children.compactMap { child in
            let values = try? child.resourceValues(forKeys: [.isSymbolicLinkKey])
            guard values?.isSymbolicLink != true else { return nil }

            let bytes = directorySize(child)
            guard bytes >= minimumBytes else { return nil }

            let nested = childEntries(for: child)
            return DiskUsageItem(
                title: child.lastPathComponent,
                path: child,
                bytes: bytes,
                purpose: purpose(for: child),
                recommendation: recommendation(for: child),
                lastAccessed: lastUsedDate(child),
                children: nested
            )
        }
    }

    private func childEntries(for url: URL) -> [DiskUsageItem] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let children = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .contentAccessDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return children.compactMap { child in
            let values = try? child.resourceValues(forKeys: [.isSymbolicLinkKey])
            guard values?.isSymbolicLink != true else { return nil }

            let bytes = directorySize(child)
            guard bytes >= 50 * 1024 * 1024 else { return nil }

            return DiskUsageItem(
                title: child.lastPathComponent,
                path: child,
                bytes: bytes,
                purpose: purpose(for: child),
                recommendation: recommendation(for: child),
                lastAccessed: lastUsedDate(child),
                children: []
            )
        }
        .sorted { $0.bytes > $1.bytes }
        .prefix(40)
        .map { $0 }
    }

    private func purpose(for url: URL) -> String {
        let path = url.path
        let name = url.lastPathComponent.lowercased()

        if path.contains("/Library/Caches") { return "App cache. Usually rebuildable, but apps may be slower the next time they start." }
        if name == "telegram desktop" { return "Telegram local messages, downloads, media cache, and app database." }
        if name.contains("whatsapp") { return "WhatsApp local media, cache, and chat support data." }
        if name.contains("signal") { return "Signal Desktop attachments, cache, and encrypted local database." }
        if name.contains("discord") { return "Discord media cache, local app state, and logs." }
        if name.contains("slack") { return "Slack workspace cache, downloads, and local database." }
        if name.contains("zalo") { return "Zalo local chat media, database, and cache." }
        if path.contains("/Library/Developer/CoreSimulator") { return "iOS simulator devices, runtimes, and temporary simulator state." }
        if path.contains("/Library/Developer/Xcode") { return "Xcode build data, symbols, archives, and developer cache." }
        if path.contains("/Library/Android") { return "Android SDKs, emulator images, Gradle/Android tooling data." }
        if name == "node_modules" { return "JavaScript project dependencies. Reinstallable with npm/pnpm/yarn." }
        if name == "build" || name == ".dart_tool" { return "Generated project build output. Rebuildable from source." }
        if path.contains("/Downloads") { return "Downloaded files. Review manually before deleting." }
        if path.contains("/Documents") { return "User documents or project data. Review carefully before deleting." }
        if path.contains("/Library/Application Support") { return "Application support data. Can include databases, downloaded media, models, and settings." }
        if path.contains("/Library/Containers") || path.contains("/Library/Group Containers") { return "Sandboxed application data. Review before deleting." }

        return "Large folder detected by disk analysis. Review contents before deleting."
    }

    private func recommendation(for url: URL) -> DiskItemRecommendation {
        let path = url.path
        let name = url.lastPathComponent.lowercased()

        if path.contains("/Library/Caches") || name == "build" || name == ".dart_tool" {
            return .removable
        }
        if name == "node_modules" || path.contains("/Downloads") || path.contains("/Library/Developer") {
            return .review
        }
        if path.contains("/Documents") || path.contains("/Pictures") || path.contains("/Movies") {
            return .keep
        }
        return .review
    }

    private func lastUsedDate(_ url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey])
        return values?.contentAccessDate ?? values?.contentModificationDate
    }

    private func expand(_ path: String) -> URL {
        if path == "~" { return home }
        if path.hasPrefix("~/") {
            return home.appendingPathComponent(String(path.dropFirst(2)))
        }
        return URL(fileURLWithPath: path)
    }

    private func directorySize(_ url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }

        if !isDirectory.boolValue {
            return fileSize(url)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            total += fileSize(fileURL)
        }
        return total
    }

    private func fileSize(_ url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]),
              values.isSymbolicLink != true,
              values.isRegularFile == true else {
            return 0
        }

        if let allocated = values.totalFileAllocatedSize ?? values.fileAllocatedSize {
            return Int64(allocated)
        }

        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64 ?? 0
    }
}
