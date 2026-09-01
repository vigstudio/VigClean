import Foundation
import Testing
@testable import VigClean

@Suite("Cleanup accounting")
struct CleanupAccountingTests {
    @Test func prunesDuplicateAndDescendantSelections() {
        let parentURL = URL(fileURLWithPath: "/Users/tester/Library/Caches/App")
        let childURL = parentURL.appendingPathComponent("cache.bin")
        let parent = CleanupPathEntry(url: parentURL, bytes: 8_192, cleanability: .removable)
        let duplicate = CleanupPathEntry(url: parentURL, bytes: 8_192, cleanability: .removable)
        let child = CleanupPathEntry(url: childURL, bytes: 4_096, cleanability: .removable)

        let plan = CleanupSelectionPlan(entries: [child, duplicate, parent])
        #expect(plan.entries.map(\.url) == [parentURL])
        #expect(plan.estimatedBytes == 8_192)
    }

    @Test func countsHiddenFilesAndHardLinksOnlyOnce() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VigClean-Accounting-\(UUID().uuidString)")
        let original = root.appendingPathComponent("payload.bin")
        let hardLink = root.appendingPathComponent("payload-copy.bin")
        let hidden = root.appendingPathComponent(".hidden-cache")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data(repeating: 7, count: 8_192).write(to: original)
        try FileManager.default.linkItem(at: original, to: hardLink)
        try Data(repeating: 9, count: 4_096).write(to: hidden)
        defer { try? FileManager.default.removeItem(at: root) }

        let calculator = AllocatedSizeCalculator()
        let expected = calculator.size(of: original) + calculator.size(of: hidden)
        #expect(expected > 0)
        #expect(calculator.size(of: root) == expected)
        #expect(calculator.size(of: [root, original, hardLink]) == expected)
    }

    @Test func deletionDispatchesAnOverlappingTreeOnlyOnce() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VigClean-DeletePlan-\(UUID().uuidString)")
        let child = root.appendingPathComponent("child.bin")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data(repeating: 3, count: 4_096).write(to: child)
        let bytes = AllocatedSizeCalculator().size(of: root)

        let childEntry = CleanupPathEntry(url: child, bytes: bytes, cleanability: .removable)
        let parentEntry = CleanupPathEntry(
            url: root,
            bytes: bytes,
            cleanability: .removable,
            children: [childEntry]
        )
        let finding = CleanupFinding(
            title: "Temporary overlap fixture",
            detail: "Test fixture",
            pathEntries: [parentEntry, childEntry],
            bytes: bytes * 2,
            risk: .safe,
            selectedByDefault: false
        )

        let result = await CleanupScanner().delete(
            [finding],
            permanently: true,
            terminateAffectedApps: false,
            requestAdminWhenNeeded: false
        )

        #expect(result.errors.isEmpty)
        #expect(result.deletedBytes == bytes)
        #expect(!FileManager.default.fileExists(atPath: root.path))
    }
}
