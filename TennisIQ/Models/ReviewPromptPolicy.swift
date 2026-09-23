import Foundation

/// Pure rules for when the app may ask for an App Store review:
/// at most once per app version, and only at a feel-good moment.
enum ReviewPromptPolicy {
    static func shouldRequest(newBestScore: Bool,
                              isPerfectRound: Bool,
                              completedRounds: Int,
                              alreadyRequested: Bool) -> Bool {
        guard !alreadyRequested else { return false }
        return newBestScore || isPerfectRound || completedRounds == 3
    }
}
