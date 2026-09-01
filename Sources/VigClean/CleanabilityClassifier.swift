import Foundation

struct CleanabilityClassifier: Sendable {
    private let validator: DeletionSafetyValidator
    private var fileManager: FileManager { .default }

    init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        validator = DeletionSafetyValidator(home: home)
    }

    func classify(
        _ url: URL,
        requiresAdministrator: Bool = false,
        userProtectedPaths: Set<String> = []
    ) -> CleanupPathCleanability {
        do {
            try validator.validate(url, userProtectedPaths: userProtectedPaths)
        } catch {
            return .protected
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return .unavailable
        }
        if isDirectory.boolValue, (try? fileManager.contentsOfDirectory(atPath: url.path)) == nil {
            return .unavailable
        }
        if requiresAdministrator || !fileManager.isWritableFile(atPath: url.deletingLastPathComponent().path) {
            return .administratorRequired
        }
        return .removable
    }
}
