import Foundation
import Combine
import GameKit
import SwiftUI

/// Thin GameKit wrapper. Pure decision logic lives in GameCenterTargets and
/// ReviewPromptPolicy so it can be tested without GameKit.
@MainActor
final class GameCenterService: ObservableObject {
    @Published private(set) var isAuthenticated = false

    init() {
        GKAccessPoint.shared.location = .bottomLeading
        GKAccessPoint.shared.showHighlights = true
        GKAccessPoint.shared.isActive = false
    }

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController {
                self.present(viewController)
                return
            }
            if GKLocalPlayer.local.isAuthenticated {
                self.isAuthenticated = true
                GKAccessPoint.shared.isActive = true
            } else {
                self.isAuthenticated = false
                GKAccessPoint.shared.isActive = false
                if let error {
                    print("Game Center authentication: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Submits the round's points to the leaderboard for this mode, if any.
    /// Free players submit rally scores too; Daily Rally is free forever.
    func submitScore(_ points: Int, mode: String) {
        guard isAuthenticated, let leaderboardID = GameCenterTargets.leaderboardID(mode: mode) else { return }
        GKLeaderboard.submitScore(points, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [leaderboardID]) { error in
            if let error {
                print("Game Center score submit: \(error.localizedDescription)")
            }
        }
    }

    /// Reports each earned badge as a completed Game Center achievement.
    func reportAchievements(_ badgeIDs: Set<String>) {
        guard isAuthenticated, !badgeIDs.isEmpty else { return }
        let achievements = badgeIDs.map { badgeID -> GKAchievement in
            let achievement = GKAchievement(identifier: GameCenterTargets.achievementID(badgeID: badgeID))
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            return achievement
        }
        GKAchievement.report(achievements) { error in
            if let error {
                print("Game Center achievement report: \(error.localizedDescription)")
            }
        }
    }

    private func present(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }
        root.present(viewController, animated: true)
    }
}
