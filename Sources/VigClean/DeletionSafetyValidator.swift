import Foundation

enum DeletionSafetyError: LocalizedError, Equatable {
    case emptyPath
    case relativePath
    case controlCharacters
    case traversal
    case symlinkRedirect(String)
    case pathChanged(String)
    case protectedRoot(String)
    case protectedByUser(String)

    var errorDescription: String? {
        switch self {
        case .emptyPath: "The deletion path is empty."
        case .relativePath: "Only absolute paths can be deleted."
        case .controlCharacters: "The path contains unsupported control characters."
        case .traversal: "The path contains a traversal component."
        case let .symlinkRedirect(path): "The path resolves through a suspicious symbolic link: \(path)"
        case let .pathChanged(path): "The path changed after validation and was not deleted: \(path)"
        case let .protectedRoot(path): "VigClean blocked a protected system or user root: \(path)"
        case let .protectedByUser(path): "This path is protected in VigClean: \(path)"
        }
    }
}

struct DeletionValidationSnapshot: Equatable, Sendable {
    let standardizedPath: String
    let resolvedPath: String
}

struct DeletionSafetyValidator: Sendable {
    private let home: URL

    init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home.standardizedFileURL
    }

    @discardableResult
    func validate(_ url: URL, userProtectedPaths: Set<String> = []) throws -> DeletionValidationSnapshot {
        let literalPath = url.path
        guard !literalPath.isEmpty else { throw DeletionSafetyError.emptyPath }
        guard literalPath.hasPrefix("/") else { throw DeletionSafetyError.relativePath }
        guard literalPath.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw DeletionSafetyError.controlCharacters
        }
        guard !literalPath.split(separator: "/", omittingEmptySubsequences: false).contains("..") else {
            throw DeletionSafetyError.traversal
        }

        let standardized = Self.canonicalizeMacOSFirmlink(url.standardizedFileURL.path)
        let resolved = Self.canonicalizeMacOSFirmlink(
            url.standardizedFileURL.resolvingSymlinksInPath().standardizedFileURL.path
        )
        try validateCanonicalPath(standardized, userProtectedPaths: userProtectedPaths)
        try validateCanonicalPath(resolved, userProtectedPaths: userProtectedPaths)

        if standardized != resolved,
           Self.scopeComponents(of: standardized) != Self.scopeComponents(of: resolved) {
            throw DeletionSafetyError.symlinkRedirect(resolved)
        }

        return DeletionValidationSnapshot(standardizedPath: standardized, resolvedPath: resolved)
    }

    func revalidate(
        _ url: URL,
        expected snapshot: DeletionValidationSnapshot,
        userProtectedPaths: Set<String> = []
    ) throws {
        let current = try validate(url, userProtectedPaths: userProtectedPaths)
        guard current == snapshot else {
            throw DeletionSafetyError.pathChanged(current.resolvedPath)
        }
    }

    private func validateCanonicalPath(_ path: String, userProtectedPaths: Set<String>) throws {
        let protectedExactRoots = Set([
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
        ].map(Self.canonicalizeMacOSFirmlink))

        let protectedSubtrees = [
            "/System/", "/bin/", "/sbin/", "/etc/", "/Library/Extensions/",
            "/private/etc/", "/private/var/db/", "/var/db/"
        ].map(Self.canonicalizeMacOSFirmlink)

        if protectedExactRoots.contains(path) || protectedSubtrees.contains(where: { path.hasPrefix($0) }) {
            throw DeletionSafetyError.protectedRoot(path)
        }

        for protectedPath in userProtectedPaths {
            let normalized = Self.canonicalizeMacOSFirmlink(
                URL(fileURLWithPath: protectedPath).standardizedFileURL.path
            )
            if path == normalized || path.hasPrefix(normalized + "/") {
                throw DeletionSafetyError.protectedByUser(normalized)
            }
        }
    }

    static func canonicalizeMacOSFirmlink(_ path: String) -> String {
        for name in ["var", "tmp", "etc"] {
            let privatePath = "/private/\(name)"
            if path == privatePath { return "/\(name)" }
            if path.hasPrefix(privatePath + "/") {
                return "/\(name)" + path.dropFirst(privatePath.count)
            }
        }
        return path
    }

    private static func scopeComponents(of path: String) -> ArraySlice<Substring> {
        path.split(separator: "/").prefix(3)
    }
}
