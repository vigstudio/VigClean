import Foundation

struct CleanupScanner: Sendable {
    private let home = FileManager.default.homeDirectoryForCurrentUser
    private let sizeCache = DirectorySizeCache()
    private var fileManager: FileManager { .default }
    private var cleanabilityClassifier: CleanabilityClassifier { CleanabilityClassifier(home: home) }

    func scan(includePrivacySensitiveFolders: Bool, progress: @MainActor (String, Double) -> Void = { _, _ in }) async -> [CleanupFinding] {
        var findings: [CleanupFinding] = []
        let stepCounter = OperationStepCounter(total: includePrivacySensitiveFolders ? 15 : 14)

        @MainActor func report(_ message: String) {
            progress(message, stepCounter.fraction())
        }

        @MainActor func advance(_ message: String) {
            progress(message, stepCounter.advance())
        }

        await report("Scanning user caches...")
        let userCachePaths = [
            "~/Library/Caches/Google",
            "~/Library/Caches/com.apple.Safari",
            "~/Library/Caches/Firefox",
            "~/Library/Caches/com.microsoft.VSCode.ShipIt",
            "~/Library/Caches/antigravity-updater",
            "~/Library/Caches/termius-updater",
            "~/Library/Caches/pencil-updater",
            "~/Library/Caches/colima",
            "~/Library/Caches/ms-playwright-go",
            "~/Library/Caches/Homebrew",
            "~/Library/Caches/composer",
            "~/Library/Caches/bun",
            "~/Library/Caches/typescript"
        ]
        await announcePaths(userCachePaths, label: "User cache") { report($0) }
        appendIfPresent(&findings, title: "User cache", detail: "Browser, updater, package manager, and app caches that can be recreated.", risk: .safe, selected: true, paths: userCachePaths)
        await advance("User cache scan complete")
        await Task.yield()

        await report("Scanning VS Code cache...")
        let vsCodePaths = [
            "~/Library/Application Support/Code/CachedExtensionVSIXs",
            "~/Library/Application Support/Code/CachedData",
            "~/Library/Application Support/Code/Cache",
            "~/Library/Application Support/Code/Code Cache",
            "~/Library/Application Support/Code/GPUCache",
            "~/Library/Application Support/Code/DawnCache",
            "~/Library/Application Support/Code/DawnGraphiteCache"
        ]
        await announcePaths(vsCodePaths, label: "VS Code cache") { report($0) }
        appendIfPresent(&findings, title: "VS Code cache", detail: "Extension packages, cached data, GPU cache, and temporary web cache.", risk: .safe, selected: true, paths: vsCodePaths)
        await advance("VS Code cache scan complete")
        await Task.yield()

        await report("Scanning Xcode derived data...")
        let xcodePaths = [
            "~/Library/Developer/Xcode/DerivedData",
            "~/Library/Developer/Xcode/iOS DeviceSupport"
        ]
        await announcePaths(xcodePaths, label: "Xcode") { report($0) }
        appendIfPresent(&findings, title: "Xcode derived data", detail: "Build output and iOS device symbols that Xcode can regenerate.", risk: .safe, selected: true, paths: xcodePaths)
        await advance("Xcode scan complete")
        await Task.yield()

        await report("Scanning Node and browser automation cache...")
        let nodeCachePaths = [
            "~/.cache/puppeteer",
            "~/.npm/_cacache",
            "~/.npm/_npx",
            "~/.npm/_logs"
        ]
        await announcePaths(nodeCachePaths, label: "Node cache") { report($0) }
        appendIfPresent(&findings, title: "Node and browser automation cache", detail: "npm, npx, logs, and Puppeteer browser cache.", risk: .safe, selected: true, paths: nodeCachePaths)
        await advance("Node cache scan complete")
        await Task.yield()

        await report("Scanning logs and Trash...")
        let logPaths = [
            "~/Library/Logs",
            "~/Library/DiagnosticReports",
            "~/.Trash"
        ]
        await announcePaths(logPaths, label: "Logs and Trash") { report($0) }
        appendIfPresent(&findings, title: "Logs and Trash", detail: "User logs and files already moved to Trash.", risk: .safe, selected: true, paths: logPaths)
        await advance("Logs and Trash scan complete")
        await Task.yield()

        await report("Scanning developer package caches...")
        let packageCachePaths = [
            "~/.gradle/caches",
            "~/.cargo/registry/cache",
            "~/.cargo/git/checkouts",
            "~/.cache/pip",
            "~/.pub-cache",
            "~/Library/Caches/CocoaPods",
            "~/Library/Caches/org.swift.swiftpm",
            "~/Library/Caches/pip",
            "~/Library/Caches/pypoetry",
            "~/Library/Caches/pnpm",
            "~/Library/Caches/yarn"
        ]
        await announcePaths(packageCachePaths, label: "Package caches") { report($0) }
        appendIfPresent(&findings, title: "Developer package caches", detail: "Gradle, Pub, CocoaPods, SwiftPM, pip, Poetry, pnpm, and yarn caches.", risk: .review, selected: true, paths: packageCachePaths)
        await advance("Package cache scan complete")
        await Task.yield()

        await report("Scanning Chrome local model cache...")
        let chromePaths = [
            "~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel"
        ]
        await announcePaths(chromePaths, label: "Chrome model cache") { report($0) }
        appendIfPresent(&findings, title: "Chrome on-device model", detail: "Large local Chrome AI/model cache that can be downloaded again.", risk: .review, selected: true, paths: chromePaths)
        await advance("Chrome model scan complete")
        await Task.yield()

        await report("Developer build artifacts • ~/Developer")
        let developerBuilds = findDirectories(under: "~/Developer", names: ["build", ".dart_tool"])
        appendIfPresent(&findings, title: "Developer build artifacts", detail: "Flutter and local project build outputs. Projects may rebuild slower next time.", risk: .review, selected: true, urls: developerBuilds)
        await advance("Developer build scan complete")
        await Task.yield()

        if includePrivacySensitiveFolders {
            await report("Large installers • ~/Downloads")
            let installers = findInstallers(under: ["~/Downloads", "~/Documents/Codex"], minimumBytes: 100 * 1024 * 1024)
            appendIfPresent(&findings, title: "Large installers and archives", detail: "Downloaded .dmg, .pkg, .zip, .iso, and compressed archives over 100 MB.", risk: .review, selected: false, urls: installers)
            await advance("Installer scan complete")
            await Task.yield()
        }

        await report("Developer dependencies • ~/Developer")
        let nodeModules = findDirectories(under: "~/Developer", names: ["node_modules"])
        appendIfPresent(&findings, title: "Developer node_modules", detail: "Project dependencies. Delete only for projects you can reinstall with npm, pnpm, or yarn.", risk: .personal, selected: false, urls: nodeModules)
        await advance("Dependency scan complete")
        await Task.yield()

        await report("Scanning messaging app data...")
        let zaloPaths = [
            "~/Library/Application Support/ZaloData"
        ]
        await announcePaths(zaloPaths, label: "Zalo data") { report($0) }
        appendIfPresent(&findings, title: "Zalo local data", detail: "Local Zalo database, media, and cache. This signs Zalo out or forces it to rebuild local data.", risk: .personal, selected: false, paths: zaloPaths)

        await appendMessagingAppData(to: &findings) { report($0) }
        await advance("Messaging data scan complete")
        await Task.yield()

        await report("Large application data • ~/Library/Application Support")
        appendLargeAppData(to: &findings)
        await advance("Large application data scan complete")
        await Task.yield()

        await report("Scanning Android SDK...")
        let androidPaths = [
            "~/Library/Android/sdk"
        ]
        await announcePaths(androidPaths, label: "Android SDK") { report($0) }
        appendIfPresent(&findings, title: "Android SDK", detail: "Android development SDK files. Delete only if you do not need Android development on this Mac.", risk: .personal, selected: false, paths: androidPaths)
        await advance("Android SDK scan complete")
        await Task.yield()

        await report("Scanning simulator devices...")
        let simulatorPaths = [
            "~/Library/Developer/CoreSimulator/Devices"
        ]
        await announcePaths(simulatorPaths, label: "Simulator devices") { report($0) }
        appendIfPresent(&findings, title: "Simulator devices", detail: "Installed iOS simulator device data. Delete only if you do not need current simulator state.", risk: .personal, selected: false, paths: simulatorPaths)
        await advance("Sorting scan results...")

        return findings
            .filter { $0.bytes > 0 }
            .sorted {
                if $0.risk.sortOrder == $1.risk.sortOrder {
                    return $0.bytes > $1.bytes
                }
                return $0.risk.sortOrder < $1.risk.sortOrder
            }
    }

    func scanInstalledApps(progress: @MainActor (String, Double) -> Void = { _, _ in }) async -> [InstalledApp] {
        await progress("Scanning installed applications...", 0)
        var apps: [InstalledApp] = []
        let appURLs = findApplications(under: ["/Applications", "~/Applications"])
        for (index, appURL) in appURLs.enumerated() {
            if Task.isCancelled { break }
            await progress("Scanning app: \(appURL.deletingPathExtension().lastPathComponent)", Double(index) / Double(max(appURLs.count, 1)))
            apps.append(installedApp(for: appURL))
            await Task.yield()
        }
        await progress("Application scan complete", 1)

        return apps.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func delete(_ findings: [CleanupFinding], permanently: Bool, terminateAffectedApps: Bool, requestAdminWhenNeeded: Bool, protectedPaths: Set<String> = [], progress: @MainActor (String, Double) -> Void = { _, _ in }) async -> DeleteResult {
        let freeBytesBefore = availableDiskBytes()
        let safetyValidator = DeletionSafetyValidator(home: home)
        if terminateAffectedApps {
            for processName in affectedProcessNames(for: findings) {
                terminateProcesses(matching: processName)
            }
        }

        var deleted: Int64 = 0
        var errors: [String] = []
        var adminEntries: [(url: URL, bytes: Int64, snapshot: DeletionValidationSnapshot)] = []
        let selectedEntries = findings.flatMap(\.pathEntries).flatMap(\.flattened)
        guard selectedEntries.count <= CleanupOperationLimits.maximumSelectedRoots else {
            return DeleteResult(
                deletedBytes: 0,
                errors: ["Operation blocked: \(selectedEntries.count) selected paths exceed the safety limit of \(CleanupOperationLimits.maximumSelectedRoots)."],
                freeBytesBefore: freeBytesBefore,
                freeBytesAfter: availableDiskBytes(),
                cancelled: false
            )
        }
        let deletionEntries = CleanupSelectionPlan(entries: selectedEntries).entries
            .filter { fileManager.fileExists(atPath: $0.url.path) }
        let totalEntries = max(deletionEntries.count, 1)
        var completedEntries = 0
        var cancelled = false

        for finding in findings {
            if finding.title.hasPrefix("Uninstall App: ") {
                let appName = finding.title.replacingOccurrences(of: "Uninstall App: ", with: "")
                terminateProcesses(matching: appName)
            }
        }

        for entry in deletionEntries {
            if Task.isCancelled {
                cancelled = true
                break
            }
            let url = entry.url
            await progress(url.path, Double(completedEntries) / Double(totalEntries))
            do {
                let snapshot = try safetyValidator.validate(url, userProtectedPaths: protectedPaths)
                let size = directorySize(url)
                if permanently, entry.requiresAdmin, requestAdminWhenNeeded {
                    adminEntries.append((url, size, snapshot))
                } else if permanently {
                    try safetyValidator.revalidate(url, expected: snapshot, userProtectedPaths: protectedPaths)
                    try fileManager.removeItem(at: url)
                    deleted += size
                } else {
                    try safetyValidator.revalidate(url, expected: snapshot, userProtectedPaths: protectedPaths)
                    _ = try fileManager.trashItem(at: url, resultingItemURL: nil)
                    deleted += size
                }
            } catch let safetyError as DeletionSafetyError {
                errors.append("\(url.path): \(safetyError.localizedDescription)")
            } catch {
                if permanently, requestAdminWhenNeeded {
                    let size = directorySize(url)
                    do {
                        let snapshot = try safetyValidator.validate(url, userProtectedPaths: protectedPaths)
                        adminEntries.append((url, size, snapshot))
                    } catch {
                        errors.append("\(url.path): \(error.localizedDescription)")
                    }
                } else {
                    errors.append("\(url.path): \(error.localizedDescription)")
                }
            }
            completedEntries += 1
            await progress(url.path, Double(completedEntries) / Double(totalEntries))
            if completedEntries.isMultiple(of: CleanupOperationLimits.chunkSize) {
                await Task.yield()
            }
        }

        if !adminEntries.isEmpty {
            let uniqueEntries = uniqueAdminEntries(adminEntries)
            do {
                for entry in uniqueEntries {
                    try safetyValidator.revalidate(entry.url, expected: entry.snapshot, userProtectedPaths: protectedPaths)
                }
                try removeWithAdministratorPrivileges(uniqueEntries.map(\.url))
                deleted += uniqueEntries.reduce(Int64(0)) { $0 + $1.bytes }
            } catch {
                errors.append("Administrator batch delete: \(error.localizedDescription)")
            }
        }

        return DeleteResult(
            deletedBytes: deleted,
            errors: errors,
            freeBytesBefore: freeBytesBefore,
            freeBytesAfter: availableDiskBytes(),
            cancelled: cancelled
        )
    }

    private func availableDiskBytes() -> Int64 {
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        if let important = values?.volumeAvailableCapacityForImportantUsage {
            return Int64(important)
        }
        if let available = values?.volumeAvailableCapacity {
            return Int64(available)
        }
        return 0
    }

    private func appendIfPresent(_ findings: inout [CleanupFinding], title: String, detail: String, risk: CleanupRisk, selected: Bool, paths: [String]) {
        appendIfPresent(&findings, title: title, detail: detail, risk: risk, selected: selected, urls: paths.map(expand))
    }

    private func appendIfPresent(_ findings: inout [CleanupFinding], title: String, detail: String, risk: CleanupRisk, selected: Bool, urls: [URL]) {
        guard !Task.isCancelled else { return }
        let entries = pathEntries(for: urls)
        let bytes = CleanupSelectionPlan(entries: entries).estimatedBytes

        guard !entries.isEmpty, bytes > 0 else { return }

        findings.append(CleanupFinding(
            title: title,
            detail: detail,
            pathEntries: entries,
            bytes: bytes,
            risk: risk,
            selectedByDefault: selected
        ))
    }

    private func appendMessagingAppData(to findings: inout [CleanupFinding], progress: @MainActor (String) -> Void) async {
        let appTargets: [(title: String, detail: String, paths: [String])] = [
            (
                "Telegram local data",
                "Telegram Desktop downloads, media cache, local database, and container data.",
                [
                    "~/Library/Application Support/Telegram Desktop",
                    "~/Library/Containers/ru.keepcoder.Telegram",
                    "~/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram",
                    "~/Library/Caches/ru.keepcoder.Telegram",
                    "~/Library/Preferences/ru.keepcoder.Telegram.plist",
                    "~/Library/Saved Application State/ru.keepcoder.Telegram.savedState"
                ]
            ),
            (
                "WhatsApp local data",
                "WhatsApp local media, cache, container, and support database.",
                [
                    "~/Library/Application Support/WhatsApp",
                    "~/Library/Containers/WhatsApp",
                    "~/Library/Containers/net.whatsapp.WhatsApp",
                    "~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared",
                    "~/Library/Caches/WhatsApp",
                    "~/Library/Caches/net.whatsapp.WhatsApp",
                    "~/Library/Preferences/net.whatsapp.WhatsApp.plist",
                    "~/Library/Saved Application State/net.whatsapp.WhatsApp.savedState"
                ]
            ),
            (
                "Signal local data",
                "Signal Desktop attachments, cache, and encrypted local database.",
                [
                    "~/Library/Application Support/Signal",
                    "~/Library/Caches/org.whispersystems.signal-desktop",
                    "~/Library/Preferences/org.whispersystems.signal-desktop.plist",
                    "~/Library/Saved Application State/org.whispersystems.signal-desktop.savedState"
                ]
            ),
            (
                "Discord local data",
                "Discord cache, media cache, logs, and local app data.",
                [
                    "~/Library/Application Support/discord",
                    "~/Library/Application Support/Discord",
                    "~/Library/Caches/com.hnc.Discord",
                    "~/Library/Logs/Discord",
                    "~/Library/Preferences/com.hnc.Discord.plist",
                    "~/Library/Saved Application State/com.hnc.Discord.savedState"
                ]
            ),
            (
                "Slack local data",
                "Slack workspaces, cache, downloads, and local database.",
                [
                    "~/Library/Application Support/Slack",
                    "~/Library/Containers/com.tinyspeck.slackmacgap",
                    "~/Library/Caches/com.tinyspeck.slackmacgap",
                    "~/Library/Preferences/com.tinyspeck.slackmacgap.plist",
                    "~/Library/Saved Application State/com.tinyspeck.slackmacgap.savedState"
                ]
            ),
            (
                "Messenger local data",
                "Facebook Messenger local cache, container, and support files.",
                [
                    "~/Library/Application Support/Messenger",
                    "~/Library/Containers/com.facebook.archon",
                    "~/Library/Caches/com.facebook.archon",
                    "~/Library/Preferences/com.facebook.archon.plist",
                    "~/Library/Saved Application State/com.facebook.archon.savedState"
                ]
            ),
            (
                "LINE local data",
                "LINE chat media, cache, container, and support database.",
                [
                    "~/Library/Application Support/LINE",
                    "~/Library/Containers/jp.naver.line.mac",
                    "~/Library/Caches/jp.naver.line.mac",
                    "~/Library/Preferences/jp.naver.line.mac.plist",
                    "~/Library/Saved Application State/jp.naver.line.mac.savedState"
                ]
            ),
            (
                "Viber local data",
                "Viber local chat media, cache, and support files.",
                [
                    "~/Library/Application Support/ViberPC",
                    "~/Library/Application Support/Viber",
                    "~/Library/Caches/com.viber.osx",
                    "~/Library/Preferences/com.viber.osx.plist",
                    "~/Library/Saved Application State/com.viber.osx.savedState"
                ]
            ),
            (
                "Skype local data",
                "Skype cache, local database, and support files.",
                [
                    "~/Library/Application Support/Skype",
                    "~/Library/Containers/com.skype.skype",
                    "~/Library/Caches/com.skype.skype",
                    "~/Library/Preferences/com.skype.skype.plist",
                    "~/Library/Saved Application State/com.skype.skype.savedState"
                ]
            ),
            (
                "WeChat local data",
                "WeChat message media, cache, container, and support files.",
                [
                    "~/Library/Application Support/com.tencent.xinWeChat",
                    "~/Library/Containers/com.tencent.xinWeChat",
                    "~/Library/Caches/com.tencent.xinWeChat",
                    "~/Library/Preferences/com.tencent.xinWeChat.plist",
                    "~/Library/Saved Application State/com.tencent.xinWeChat.savedState"
                ]
            )
        ]

        for target in appTargets {
            await announcePaths(target.paths, label: target.title, progress: progress)
            appendIfPresent(
                &findings,
                title: target.title,
                detail: target.detail,
                risk: .personal,
                selected: false,
                paths: target.paths
            )
        }
    }

    private func announcePaths(_ paths: [String], label: String, progress: @MainActor (String) -> Void) async {
        for path in paths {
            await progress("\(label) • \(expand(path).path)")
            await Task.yield()
        }
    }

    private func appendLargeAppData(to findings: inout [CleanupFinding]) {
        let roots = [
            "~/Library/Application Support",
            "~/Library/Containers",
            "~/Library/Group Containers"
        ]
        let minimumBytes: Int64 = 500 * 1024 * 1024
        let candidates = roots.flatMap { largeChildren(under: $0, minimumBytes: minimumBytes) }
        let knownPaths = Set(findings.flatMap(\.paths).map { $0.standardizedFileURL.path })
        let unknown = candidates.filter { !knownPaths.contains($0.standardizedFileURL.path) }

        appendIfPresent(
            &findings,
            title: "Large application data",
            detail: "Large app support/container folders detected automatically. Review each folder before deleting.",
            risk: .personal,
            selected: false,
            urls: unknown
        )
    }

    private func largeChildren(under root: String, minimumBytes: Int64) -> [URL] {
        guard !Task.isCancelled else { return [] }
        let rootURL = expand(root)
        guard fileManager.fileExists(atPath: rootURL.path),
              let children = try? fileManager.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return children
            .filter { child in
                let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                return values?.isDirectory == true && values?.isSymbolicLink != true
            }
            .filter { directorySize($0) >= minimumBytes }
            .sorted { directorySize($0) > directorySize($1) }
    }

    private func expand(_ path: String) -> URL {
        if path == "~" { return home }
        if path.hasPrefix("~/") {
            return home.appendingPathComponent(String(path.dropFirst(2)))
        }
        return URL(fileURLWithPath: path)
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard !Task.isCancelled else { return 0 }
        let cacheKey = url.standardizedFileURL.path
        if let cached = sizeCache.value(for: cacheKey) {
            return cached
        }

        let total = AllocatedSizeCalculator().size(of: url)
        sizeCache.insert(total, for: cacheKey)
        return total
    }

    private func findDirectories(under root: String, names: Set<String>) -> [URL] {
        guard !Task.isCancelled else { return [] }
        let rootURL = expand(root)
        guard fileManager.fileExists(atPath: rootURL.path),
              let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
              ) else {
            return []
        }

        var results: [URL] = []
        for case let url as URL in enumerator {
            if Task.isCancelled { break }
            guard names.contains(url.lastPathComponent) else { continue }
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values?.isDirectory == true, values?.isSymbolicLink != true else { continue }
            results.append(url)
            enumerator.skipDescendants()
        }
        return results
    }

    private func findInstallers(under roots: [String], minimumBytes: Int64) -> [URL] {
        guard !Task.isCancelled else { return [] }
        let extensions = Set(["dmg", "pkg", "zip", "iso", "tgz", "gz", "xz"])
        var results: [URL] = []

        for root in roots.map(expand) where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let url as URL in enumerator {
                if Task.isCancelled { break }
                guard extensions.contains(url.pathExtension.lowercased()) else { continue }
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .isSymbolicLinkKey])
                guard values?.isRegularFile == true, values?.isSymbolicLink != true, Int64(values?.fileSize ?? 0) >= minimumBytes else { continue }
                results.append(url)
            }
        }

        return results
    }

    private func installedApp(for appURL: URL) -> InstalledApp {
        let appName = appURL.deletingPathExtension().lastPathComponent
        let bundle = Bundle(url: appURL)
        let bundleID = bundle?.bundleIdentifier
        let paths = uninstallPaths(forAppAt: appURL, appName: appName, bundleID: bundleID)
        let entries = pathEntries(for: paths)
        let bytes = CleanupSelectionPlan(entries: entries).estimatedBytes

        return InstalledApp(
            name: appName,
            bundleID: bundleID,
            appURL: appURL,
            relatedEntries: entries,
            totalBytes: bytes
        )
    }

    private func findApplications(under roots: [String]) -> [URL] {
        var results: [URL] = []

        for root in roots.map(expand) where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension.lowercased() == "app" else { continue }
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey])
                guard values?.isDirectory == true, values?.isSymbolicLink != true else { continue }
                results.append(url)
                enumerator.skipDescendants()
            }
        }

        return results.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }

    private func uninstallPaths(forAppAt appURL: URL, appName: String, bundleID: String?) -> [URL] {
        var paths = [appURL]
        let names = appNameCandidates(appName)

        for name in names {
            paths.append(expand("~/Library/Application Support/\(name)"))
            paths.append(expand("~/Library/Caches/\(name)"))
            paths.append(expand("~/Library/Logs/\(name)"))
        }

        if let bundleID, !bundleID.isEmpty {
            paths.append(contentsOf: [
                expand("~/Library/Application Support/\(bundleID)"),
                expand("~/Library/Caches/\(bundleID)"),
                expand("~/Library/HTTPStorages/\(bundleID)"),
                expand("~/Library/HTTPStorages/\(bundleID).binarycookies"),
                expand("~/Library/Preferences/\(bundleID).plist"),
                expand("~/Library/Saved Application State/\(bundleID).savedState"),
                expand("~/Library/Containers/\(bundleID)"),
                expand("~/Library/WebKit/\(bundleID)"),
                expand("~/Library/Logs/\(bundleID)")
            ])
            paths.append(contentsOf: matchingChildren(under: "~/Library/Group Containers", containing: bundleID))
        }

        return paths
    }

    private func appNameCandidates(_ appName: String) -> [String] {
        var names = [appName]
        let noSpaces = appName.replacingOccurrences(of: " ", with: "")
        if noSpaces != appName {
            names.append(noSpaces)
        }
        return Array(Set(names))
    }

    private func matchingChildren(under root: String, containing needle: String) -> [URL] {
        let rootURL = expand(root)
        guard fileManager.fileExists(atPath: rootURL.path),
              let children = try? fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil) else {
            return []
        }

        return children.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(needle) }
    }

    private func unique(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter { seen.insert($0.standardizedFileURL.path).inserted }
    }

    private func pathEntries(for urls: [URL]) -> [CleanupPathEntry] {
        guard !Task.isCancelled else { return [] }
        return unique(urls)
            .filter { fileManager.fileExists(atPath: $0.path) }
            .map { url in
                let requiresAdmin = requiresAdministratorPrivileges(url)
                return CleanupPathEntry(
                    url: url,
                    bytes: directorySize(url),
                    cleanability: cleanabilityClassifier.classify(url, requiresAdministrator: requiresAdmin),
                    children: childEntries(for: url)
                )
            }
    }

    private func childEntries(for url: URL) -> [CleanupPathEntry] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let children = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return children
            .filter { child in
                let values = try? child.resourceValues(forKeys: [.isSymbolicLinkKey])
                return values?.isSymbolicLink != true
            }
            .map { child in
                let requiresAdmin = requiresAdministratorPrivileges(child)
                return CleanupPathEntry(
                    url: child,
                    bytes: directorySize(child),
                    cleanability: cleanabilityClassifier.classify(child, requiresAdministrator: requiresAdmin)
                )
            }
            .filter { $0.bytes > 0 }
            .sorted { $0.bytes > $1.bytes }
            .prefix(80)
            .map { $0 }
    }

    private func requiresAdministratorPrivileges(_ url: URL) -> Bool {
        if url.path.hasPrefix("/Applications/") || url.path == "/Applications" {
            return !fileManager.isWritableFile(atPath: url.path)
        }

        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let ownerAccountID = attributes[.ownerAccountID] as? NSNumber else {
            return false
        }

        return ownerAccountID.intValue == 0 && !fileManager.isWritableFile(atPath: url.path)
    }

    private func terminateProcesses(matching name: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        process.arguments = ["-f", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    private func affectedProcessNames(for findings: [CleanupFinding]) -> [String] {
        let selectedPaths = findings
            .flatMap(\.pathEntries)
            .flatMap(\.flattened)
            .map { $0.url.path.lowercased() }

        let appRules: [(needles: [String], processes: [String])] = [
            (["zalodata"], ["Zalo", "zalo"]),
            (["telegram desktop", "ru.keepcoder.telegram"], ["Telegram", "Telegram Desktop"]),
            (["whatsapp", "net.whatsapp"], ["WhatsApp"]),
            (["signal", "org.whispersystems.signal-desktop"], ["Signal"]),
            (["discord", "com.hnc.discord"], ["Discord", "discord"]),
            (["slack", "com.tinyspeck.slackmacgap"], ["Slack"]),
            (["messenger", "com.facebook.archon"], ["Messenger"]),
            (["/line", "jp.naver.line.mac"], ["LINE"]),
            (["viber", "com.viber.osx"], ["Viber"]),
            (["skype", "com.skype.skype"], ["Skype"]),
            (["wechat", "xinwechat", "com.tencent.xinwechat"], ["WeChat", "Weixin"])
        ]

        var processes = Set<String>()
        for path in selectedPaths {
            for rule in appRules where rule.needles.contains(where: { path.contains($0) }) {
                processes.formUnion(rule.processes)
            }
        }
        return processes.sorted()
    }

    private func uniqueAdminEntries(
        _ entries: [(url: URL, bytes: Int64, snapshot: DeletionValidationSnapshot)]
    ) -> [(url: URL, bytes: Int64, snapshot: DeletionValidationSnapshot)] {
        var seen = Set<String>()
        return entries.filter { seen.insert($0.url.standardizedFileURL.path).inserted }
    }

    private func removeWithAdministratorPrivileges(_ urls: [URL]) throws {
        guard !urls.isEmpty else { return }

        let process = Process()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e", "on run argv",
            "-e", "set deleteCommand to \"\"",
            "-e", "repeat with targetPath in argv",
            "-e", "set deleteCommand to deleteCommand & \"/bin/rm -rf -- \" & quoted form of (targetPath as text) & \"; \"",
            "-e", "end repeat",
            "-e", "do shell script deleteCommand with administrator privileges with prompt \"VigClean needs administrator permission to remove selected protected files.\"",
            "-e", "end run"
        ] + urls.map(\.path)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            throw NSError(
                domain: "VigClean.AdminDelete",
                code: Int(process.terminationStatus),
                userInfo: [
                    NSLocalizedDescriptionKey: message?.isEmpty == false
                        ? message!
                        : "Administrator delete was cancelled or failed."
                ]
            )
        }
    }
}

private final class DirectorySizeCache: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Int64] = [:]

    func value(for path: String) -> Int64? {
        lock.lock()
        defer { lock.unlock() }
        return values[path]
    }

    func insert(_ value: Int64, for path: String) {
        lock.lock()
        values[path] = value
        lock.unlock()
    }
}
