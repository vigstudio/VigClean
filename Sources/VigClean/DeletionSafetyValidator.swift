import Foundation

enum DeletionSafetyError: LocalizedError, Equatable {
    case emptyPath
    case relativePath
    case controlCharacters
    case traversal
    case protectedRoot(String)
    case protectedByUser(String)

    var errorDescription: String? {
        switch self {
        case .emptyPath: "The deletion path is empty."
        case .relativePath: "Only absolute paths can be deleted."
        case .controlCharacters: "The path contains unsupported control characters."
        case .traversal: "The path contains a traversal component."
        case let .protectedRoot(path): "VigClean blocked a protected system or user root: \(path)"
        case let .protectedByUser(path): "This path is protected in VigClean: \(path)"
        }
    }
}

struct DeletionSafetyValidator: Sendable {
    private let home: URL

    init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home.standardizedFileURL
    }

    func validate(_ url: URL, userProtectedPaths: Set<String> = []) throws {
        let literalPath = url.path
        guard !literalPath.isEmpty else { throw DeletionSafetyError.emptyPath }
        guard literalPath.hasPrefix("/") else { throw DeletionSafetyError.relativePath }
        guard literalPath.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw DeletionSafetyError.controlCharacters
        }
        guard !literalPath.split(separator: "/", omittingEmptySubsequences: false).contains("..") else {
            throw DeletionSafetyError.traversal
        }

        let standardized = url.standardizedFileURL
        let resolved = standardized.resolvingSymlinksInPath().standardizedFileURL
        try validateCanonicalPath(standardized.path, userProtectedPaths: userProtectedPaths)
        try validateCanonicalPath(resolved.path, userProtectedPaths: userProtectedPaths)
    }

    private func validateCanonicalPath(_ path: String, userProtectedPaths: Set<String>) throws {
        let protectedExactRoots: Set<String> = [
            "/", "/Applications", "/Library", "/Library/Application Support",
            "/System", "/Users", "/Volumes", "/bin", "/sbin", "/usr", "/etc",
            "/private", "/var", home.path,
            home.appendingPathComponent("Desktop").path,
            home.appendingPathComponent("Documents").path,
            home.appendingPathComponent("Downloads").path,
            home.appendingPathComponent("Movies").path,
            home.appendingPathComponent("Music").path,
            home.appendingPathComponent("Pictures").path,
            home.appendingPathComponent("Library").path
        ]

        let protectedSubtrees = [
            "/System/", "/bin/", "/sbin/", "/etc/", "/Library/Extensions/",
            "/private/etc/", "/private/var/db/", "/var/db/"
        ]

        if protectedExactRoots.contains(path) || protectedSubtrees.contains(where: { path.hasPrefix($0) }) {
            throw DeletionSafetyError.protectedRoot(path)
        }

        for protectedPath in userProtectedPaths {
            let normalized = URL(fileURLWithPath: protectedPath).standardizedFileURL.path
            if path == normalized || path.hasPrefix(normalized + "/") {
                throw DeletionSafetyError.protectedByUser(normalized)
            }
        }
    }
}
