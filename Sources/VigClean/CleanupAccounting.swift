import Foundation

struct CleanupSelectionPlan: Sendable {
    let entries: [CleanupPathEntry]

    init(findings: [CleanupFinding]) {
        self.init(entries: findings.flatMap(\.pathEntries))
    }

    init(entries: [CleanupPathEntry]) {
        let candidates = entries.flatMap(\.flattened).sorted {
            let left = Self.pathComponents($0.url).count
            let right = Self.pathComponents($1.url).count
            if left == right { return $0.url.path < $1.url.path }
            return left < right
        }

        var kept: [CleanupPathEntry] = []
        var keptPaths: [String] = []
        for entry in candidates {
            let path = Self.canonicalPath(entry.url)
            guard !keptPaths.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) else { continue }
            kept.append(entry.withoutChildrenForAccounting())
            keptPaths.append(path)
        }
        self.entries = kept
    }

    var estimatedBytes: Int64 {
        entries.reduce(Int64(0)) { $0 + $1.bytes }
    }

    private static func canonicalPath(_ url: URL) -> String {
        DeletionSafetyValidator.canonicalizeMacOSFirmlink(url.standardizedFileURL.path)
    }

    private static func pathComponents(_ url: URL) -> [Substring] {
        canonicalPath(url).split(separator: "/")
    }
}

struct AllocatedSizeCalculator: Sendable {
    private struct FileIdentity: Hashable {
        let device: UInt64
        let inode: UInt64
    }

    func size(of root: URL) -> Int64 {
        size(of: [root])
    }

    func size(of roots: [URL]) -> Int64 {
        let fileManager = FileManager.default
        var identities = Set<FileIdentity>()
        var paths = Set<String>()
        var total: Int64 = 0

        func countFile(_ url: URL) {
            guard let values = try? url.resourceValues(forKeys: [
                .isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey,
            ]), values.isRegularFile == true, values.isSymbolicLink != true else { return }

            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            if let device = (attributes?[.systemNumber] as? NSNumber)?.uint64Value,
               let inode = (attributes?[.systemFileNumber] as? NSNumber)?.uint64Value {
                guard identities.insert(FileIdentity(device: device, inode: inode)).inserted else { return }
            } else {
                guard paths.insert(url.standardizedFileURL.path).inserted else { return }
            }

            if let allocated = values.totalFileAllocatedSize ?? values.fileAllocatedSize {
                total += Int64(allocated)
            } else if let logical = attributes?[.size] as? NSNumber {
                total += logical.int64Value
            }
        }

        for root in roots {
            if Task.isCancelled { break }
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else { continue }
            if !isDirectory.boolValue {
                countFile(root)
                continue
            }

            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [
                    .isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey,
                    .totalFileAllocatedSizeKey, .fileAllocatedSizeKey,
                ],
                options: [],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let url as URL in enumerator {
                if Task.isCancelled { break }
                let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
                if values?.isSymbolicLink == true {
                    if values?.isDirectory == true { enumerator.skipDescendants() }
                    continue
                }
                countFile(url)
            }
        }
        return total
    }
}

private extension CleanupPathEntry {
    func withoutChildrenForAccounting() -> CleanupPathEntry {
        CleanupPathEntry(url: url, bytes: bytes, cleanability: cleanability)
    }
}
