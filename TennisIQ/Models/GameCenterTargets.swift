import Foundation

/// Pure mapping between local game state and Game Center identifiers.
/// No GameKit import here, so this stays unit-testable with swiftc.
enum GameCenterTargets {
    static let leaderboardRally = "com.srqtennis.TennisIQ.leaderboard.rally"
    static let leaderboardTimed = "com.srqtennis.TennisIQ.leaderboard.timed"

    static func leaderboardID(mode: String) -> String? {
        switch mode {
        case "rally": return leaderboardRally
        case "timed": return leaderboardTimed
        default: return nil
        }
    }

    static func achievementID(badgeID: String) -> String {
        "com.srqtennis.TennisIQ.achievement.\(badgeID)"
    }
}
