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
}
