import Foundation

// Run from the project root:
// swiftc TennisIQ/Models/ReviewPromptPolicy.swift tests/ReviewPromptTests.swift -o /tmp/tennisiq-review-tests
// /tmp/tennisiq-review-tests
@main
struct ReviewPromptTests {
    static var checks = 0

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        checks += 1
        guard condition() else { fatalError("FAILED: \(message)") }
    }

    static func main() {
        expect(ReviewPromptPolicy.shouldRequest(newBestScore: true, isPerfectRound: false, completedRounds: 5, alreadyRequested: false), "new personal best prompts")
        expect(ReviewPromptPolicy.shouldRequest(newBestScore: false, isPerfectRound: true, completedRounds: 5, alreadyRequested: false), "perfect round prompts")
        expect(ReviewPromptPolicy.shouldRequest(newBestScore: false, isPerfectRound: false, completedRounds: 3, alreadyRequested: false), "third completed round prompts")
        expect(!ReviewPromptPolicy.shouldRequest(newBestScore: false, isPerfectRound: false, completedRounds: 2, alreadyRequested: false), "ordinary early round does not prompt")
        expect(!ReviewPromptPolicy.shouldRequest(newBestScore: true, isPerfectRound: true, completedRounds: 3, alreadyRequested: true), "never twice in one version")
        expect(!ReviewPromptPolicy.shouldRequest(newBestScore: false, isPerfectRound: false, completedRounds: 3, alreadyRequested: true), "already requested blocks third-round prompt")
        print("ReviewPromptPolicy: \(checks) checks passed")
    }
}
