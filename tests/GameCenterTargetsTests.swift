import Foundation

// Run from the project root:
// swiftc TennisIQ/Models/GameCenterTargets.swift tests/GameCenterTargetsTests.swift -o /tmp/tennisiq-gctargets-tests
// /tmp/tennisiq-gctargets-tests
@main
struct GameCenterTargetsTests {
    static var checks = 0

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        checks += 1
        guard condition() else { fatalError("FAILED: \(message)") }
    }

    static func main() {
        expect(GameCenterTargets.leaderboardID(mode: "rally") == "com.srqtennis.TennisIQ.leaderboard.rally", "rally leaderboard id")
        expect(GameCenterTargets.leaderboardID(mode: "timed") == "com.srqtennis.TennisIQ.leaderboard.timed", "timed leaderboard id")
        expect(GameCenterTargets.leaderboardID(mode: "placement") == nil, "placement publishes no leaderboard")
        expect(GameCenterTargets.leaderboardID(mode: "challenge") == nil, "challenge publishes no leaderboard")
        expect(GameCenterTargets.achievementID(badgeID: "perfect-round") == "com.srqtennis.TennisIQ.achievement.perfect-round", "achievement id format")
        expect(GameCenterTargets.achievementID(badgeID: "all-nine-categories-firstcorrect") == "com.srqtennis.TennisIQ.achievement.all-nine-categories-firstcorrect", "long badge id format")
        print("GameCenterTargets: \(checks) checks passed")
    }
}
