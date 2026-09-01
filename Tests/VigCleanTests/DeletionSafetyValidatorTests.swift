import Foundation
import Testing
@testable import VigClean

@Suite("Deletion safety")
struct DeletionSafetyValidatorTests {
    private let home = URL(fileURLWithPath: "/Users/tester")

    @Test func allowsARegularCacheChild() throws {
        let validator = DeletionSafetyValidator(home: home)
        try validator.validate(URL(fileURLWithPath: "/Users/tester/Library/Caches/com.example.app"))
    }

    @Test func blocksCriticalAndBareRoots() {
        let validator = DeletionSafetyValidator(home: home)
        for path in ["/", "/System/Library", "/Applications", "/Users/tester", "/Users/tester/Documents"] {
            #expect(throws: DeletionSafetyError.self) {
                try validator.validate(URL(fileURLWithPath: path))
            }
        }
    }

    @Test func blocksUserProtectedDescendants() {
        let validator = DeletionSafetyValidator(home: home)
        #expect(throws: DeletionSafetyError.self) {
            try validator.validate(
                URL(fileURLWithPath: "/Users/tester/Developer/Client/App/build"),
                userProtectedPaths: ["/Users/tester/Developer/Client"]
            )
        }
    }

    @Test func canonicalizesKnownMacOSFirmlinks() {
        #expect(DeletionSafetyValidator.canonicalizeMacOSFirmlink("/private/var/log/app.log") == "/var/log/app.log")
        #expect(DeletionSafetyValidator.canonicalizeMacOSFirmlink("/private/tmp/build") == "/tmp/build")
        #expect(DeletionSafetyValidator.canonicalizeMacOSFirmlink("/private/etc/hosts") == "/etc/hosts")
        #expect(DeletionSafetyValidator.canonicalizeMacOSFirmlink("/private/example") == "/private/example")
    }

    @Test func blocksSymlinkRedirectOutsideOriginalScope() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VigClean-Symlink-\(UUID().uuidString)")
        let link = root.appendingPathComponent("redirect")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: URL(fileURLWithPath: "/System"))
        defer { try? FileManager.default.removeItem(at: root) }

        let validator = DeletionSafetyValidator(home: URL(fileURLWithPath: "/Users/tester"))
        #expect(throws: DeletionSafetyError.self) {
            try validator.validate(link)
        }
    }

    @Test func detectsTargetChangeBetweenValidationAndDeletion() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VigClean-Revalidation-\(UUID().uuidString)")
        let first = root.appendingPathComponent("first")
        let second = root.appendingPathComponent("second")
        let link = root.appendingPathComponent("candidate")
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: first)
        defer { try? FileManager.default.removeItem(at: root) }

        let validator = DeletionSafetyValidator(home: URL(fileURLWithPath: "/Users/tester"))
        let snapshot = try validator.validate(link)
        try FileManager.default.removeItem(at: link)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: second)

        #expect(throws: DeletionSafetyError.self) {
            try validator.revalidate(link, expected: snapshot)
        }
    }
}
