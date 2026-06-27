import Foundation

struct CleanupScanner: Sendable {
    private let home = FileManager.default.homeDirectoryForCurrentUser
    private var fileManager: FileManager { .default }

    func scan(includePrivacySensitiveFolders: Bool, progress: @MainActor (String) -> Void = { _ in }) async -> [CleanupFinding] {
        var findings: [CleanupFinding] = []

        await progress("Scanning user caches...")
        let userCachePaths = [
            "~/Library/Caches/Google",
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
        await announcePaths(userCachePaths, label: "User cache", progress: progress)
        appendIfPresent(&findings, title: "User cache", detail: "Browser, updater, package manager, and app caches that can be recreated.", risk: .safe, selected: true, paths: userCachePaths)
        await Task.yield()

        await progress("Scanning VS Code cache...")
        let vsCodePaths = [
            "~/Library/Application Support/Code/CachedExtensionVSIXs",
            "~/Library/Application Support/Code/CachedData",
            "~/Library/Application Support/Code/Cache",
            "~/Library/Application Support/Code/Code Cache",
            "~/Library/Application Support/Code/GPUCache",
            "~/Library/Application Support/Code/DawnCache",
            "~/Library/Application Support/Code/DawnGraphiteCache"
        ]
        await announcePaths(vsCodePaths, label: "VS Code cache", progress: progress)
        appendIfPresent(&findings, title: "VS Code cache", detail: "Extension packages, cached data, GPU cache, and temporary web cache.", risk: .safe, selected: true, paths: vsCodePaths)
        await Task.yield()

        await progress("Scanning Xcode derived data...")
        let xcodePaths = [
            "~/Library/Developer/Xcode/DerivedData",
            "~/Library/Developer/Xcode/iOS DeviceSupport"
        ]
        await announcePaths(xcodePaths, label: "Xcode", progress: progress)
        appendIfPresent(&findings, title: "Xcode derived data", detail: "Build output and iOS device symbols that Xcode can regenerate.", risk: .safe, selected: true, paths: xcodePaths)
        await Task.yield()

        await progress("Scanning Node and browser automation cache...")
        let nodeCachePaths = [
            "~/.cache/puppeteer",
            "~/.npm/_cacache",
            "~/.npm/_npx",
            "~/.npm/_logs"
        ]
        await announcePaths(nodeCachePaths, label: "Node cache", progress: progress)
        appendIfPresent(&findings, title: "Node and browser automation cache", detail: "npm, npx, logs, and Puppeteer browser cache.", risk: .safe, selected: true, paths: nodeCachePaths)
        await Task.yield()

        await progress("Scanning logs and Trash...")
        let logPaths = [
            "~/Library/Logs",
            "~/.Trash"
        ]
        await announcePaths(logPaths, label: "Logs and Trash", progress: progress)
        appendIfPresent(&findings, title: "Logs and Trash", detail: "User logs and files already moved to Trash.", risk: .safe, selected: true, paths: logPaths)
        await Task.yield()

        await progress("Scanning developer package caches...")
        let packageCachePaths = [
            "~/.gradle/caches",
            "~/.pub-cache",
            "~/Library/Caches/CocoaPods",
            "~/Library/Caches/org.swift.swiftpm",
            "~/Library/Caches/pip",
            "~/Library/Caches/pypoetry",
            "~/Library/Caches/pnpm",
            "~/Library/Caches/yarn"
        ]
        await announcePaths(packageCachePaths, label: "Package caches", progress: progress)
        appendIfPresent(&findings, title: "Developer package caches", detail: "Gradle, Pub, CocoaPods, SwiftPM, pip, Poetry, pnpm, and yarn caches.", risk: .review, selected: true, paths: packageCachePaths)
        await Task.yield()

        await progress("Scanning Chrome local model cache...")
        let chromePaths = [
            "~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel"
        ]
        await announcePaths(chromePaths, label: "Chrome model cache", progress: progress)
        appendIfPresent(&findings, title: "Chrome on-device model", detail: "Large local Chrome AI/model cache that can be downloaded again.", risk: .review, selected: true, paths: chromePaths)
        await Task.yield()

        await progress("Developer build artifacts • ~/Developer")
        let developerBuilds = findDirectories(under: "~/Developer", names: ["build", ".dart_tool"])
        appendIfPresent(&findings, title: "Developer build artifacts", detail: "Flutter and local project build outputs. Projects may rebuild slower next time.", risk: .review, selected: true, urls: developerBuilds)
        await Task.yield()

        if includePrivacySensitiveFolders {
            await progress("Large installers • ~/Downloads")
            let installers = findInstallers(under: ["~/Downloads", "~/Documents/Codex"], minimumBytes: 100 * 1024 * 1024)
            appendIfPresent(&findings, title: "Large installers and archives", detail: "Downloaded .dmg, .pkg, .zip, .iso, and compressed archives over 100 MB.", risk: .review, selected: false, urls: installers)
            await Task.yield()
        }

        await progress("Developer dependencies • ~/Developer")
        let nodeModules = findDirectories(under: "~/Developer", names: ["node_modules"])
        appendIfPresent(&findings, title: "Developer node_modules", detail: "Project dependencies. Delete only for projects you can reinstall with npm, pnpm, or yarn.", risk: .personal, selected: false, urls: nodeModules)
        await Task.yield()

        await progress("Scanning messaging app data...")
        let zaloPaths = [
            "~/Library/Application Support/ZaloData"
        ]
        await announcePaths(zaloPaths, label: "Zalo data", progress: progress)
        appendIfPresent(&findings, title: "Zalo local data", detail: "Local Zalo database, media, and cache. This signs Zalo out or forces it to rebuild local data.", risk: .personal, selected: false, paths: zaloPaths)

        await appendMessagingAppData(to: &findings, progress: progress)
        await Task.yield()

        await progress("Large application data • ~/Library/Application Support")
        appendLargeAppData(to: &findings)
        await Task.yield()

        await progress("Scanning Android SDK...")
        let androidPaths = [
            "~/Library/Android/sdk"
        ]
        await announcePaths(androidPaths, label: "Android SDK", progress: progress)
        appendIfPresent(&findings, title: "Android SDK", detail: "Android development SDK files. Delete only if you do not need Android development on this Mac.", risk: .personal, selected: false, paths: androidPaths)
        await Task.yield()

        await progress("Scanning simulator devices...")
        let simulatorPaths = [
            "~/Library/Developer/CoreSimulator/Devices"
        ]
        await announcePaths(simulatorPaths, label: "Simulator devices", progress: progress)
        appendIfPresent(&findings, title: "Simulator devices", detail: "Installed iOS simulator device data. Delete only if you do not need current simulator state.", risk: .personal, selected: false, paths: simulatorPaths)
        await progress("Sorting scan results...")

        return findings
            .filter { $0.bytes > 0 }
            .sorted {
                if $0.risk.sortOrder == $1.risk.sortOrder {
                    return $0.bytes > $1.bytes
                }
                return $0.risk.sortOrder < $1.risk.sortOrder
            }
    }

    func scanInstalledApps(progress: @MainActor (String) -> Void = { _ in }) async -> [InstalledApp] {
        await progress("Scanning installed applications...")
        var apps: [InstalledApp] = []
        for appURL in findApplications(under: ["/Applications", "~/Applications"]) {
            await progress("Scanning app: \(appURL.deletingPathExtension().lastPathComponent)")
            apps.append(installedApp(for: appURL))
            await Task.yield()
        }

        return apps.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func delete(_ findings: [CleanupFinding], permanently: Bool, terminateAffectedApps: Bool, requestAdminWhenNeeded: Bool) async -> DeleteResult {
        if terminateAffectedApps {
            for processName in affectedProcessNames(for: findings) {
                terminateProcesses(matching: processName)
            }
        }

        var deleted: Int64 = 0
        var errors: [String] = []
        var adminEntries: [(url: URL, bytes: Int64)] = []

        for finding in findings {
            if finding.title.hasPrefix("Uninstall App: ") {
                let appName = finding.title.replacingOccurrences(of: "Uninstall App: ", with: "")
                terminateProcesses(matching: appName)
            }

            for entry in finding.pathEntries.flatMap(\.flattened) where fileManager.fileExists(atPath: entry.url.path) {
                let url = entry.url
                do {
                    let size = directorySize(url)
                    if permanently, entry.requiresAdmin, requestAdminWhenNeeded {
                        adminEntries.append((url, size))
                    } else if permanently {
                        try fileManager.removeItem(at: url)
                        deleted += size
                    } else {
                        _ = try fileManager.trashItem(at: url, resultingItemURL: nil)
                        deleted += size
                    }
                } catch {
                    if permanently, requestAdminWhenNeeded {
                        let size = directorySize(url)
                        adminEntries.append((url, size))
                    } else {
                        errors.append("\(url.path): \(error.localizedDescription)")
                    }
                }
            }
        }

        if !adminEntries.isEmpty {
            let uniqueEntries = uniqueAdminEntries(adminEntries)
            do {
                try removeWithAdministratorPrivileges(uniqueEntries.map(\.url))
                deleted += uniqueEntries.reduce(Int64(0)) { $0 + $1.bytes }
            } catch {
                errors.append("Administrator batch delete: \(error.localizedDescription)")
            }
        }

        return DeleteResult(deletedBytes: deleted, errors: errors)
    }

    private func appendIfPresent(_ findings: inout [CleanupFinding], title: String, detail: String, risk: CleanupRisk, selected: Bool, paths: [String]) {
        appendIfPresent(&findings, title: title, detail: detail, risk: risk, selected: selected, urls: paths.map(expand))
    }

    private func appendIfPresent(_ findings: inout [CleanupFinding], title: String, detail: String, risk: CleanupRisk, selected: Bool, urls: [URL]) {
        let entries = pathEntries(for: urls)
        let bytes = entries.reduce(Int64(0)) { $0 + $1.bytes }

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

    private func findDirectories(under root: String, names: Set<String>) -> [URL] {
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
            guard names.contains(url.lastPathComponent) else { continue }
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard values?.isDirectory == true, values?.isSymbolicLink != true else { continue }
            results.append(url)
            enumerator.skipDescendants()
        }
        return results
    }

    private func findInstallers(under roots: [String], minimumBytes: Int64) -> [URL] {
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
        let bytes = entries.reduce(Int64(0)) { $0 + $1.bytes }

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
        unique(urls)
            .filter { fileManager.fileExists(atPath: $0.path) }
            .map { url in
                CleanupPathEntry(
                    url: url,
                    bytes: directorySize(url),
                    requiresAdmin: requiresAdministratorPrivileges(url),
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
                CleanupPathEntry(
                    url: child,
                    bytes: directorySize(child),
                    requiresAdmin: requiresAdministratorPrivileges(child)
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

    private func uniqueAdminEntries(_ entries: [(url: URL, bytes: Int64)]) -> [(url: URL, bytes: Int64)] {
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
