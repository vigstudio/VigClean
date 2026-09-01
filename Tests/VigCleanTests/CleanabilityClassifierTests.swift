import Foundation
import Testing
@testable import VigClean

@Suite("Cleanup path cleanability")
struct CleanabilityClassifierTests {
    @Test func classifiesRemovableUnavailableAndAdminPaths() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VigClean-Cleanability-\(UUID().uuidString)")
        let candidate = root.appendingPathComponent("candidate")
        try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let classifier = CleanabilityClassifier(home: root)
        #expect(classifier.classify(candidate) == .removable)
        #expect(classifier.classify(root.appendingPathComponent("missing")) == .unavailable)
        #expect(classifier.classify(candidate, requiresAdministrator: true) == .administratorRequired)
    }

    @Test func classifiesBuiltInAndUserProtectedPaths() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VigClean-Protected-\(UUID().uuidString)")
        let candidate = root.appendingPathComponent("candidate")
        try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let classifier = CleanabilityClassifier(home: root)
        #expect(classifier.classify(root) == .protected)
        #expect(classifier.classify(candidate, userProtectedPaths: [root.path]) == .protected)
    }
}
