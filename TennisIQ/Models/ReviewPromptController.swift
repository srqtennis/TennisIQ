import Foundation
import Combine
import StoreKit
import UIKit

/// Decides via ReviewPromptPolicy whether a review request is appropriate,
/// then shows the StoreKit review sheet and records that it asked for this
/// app version, so it never asks twice for the same version.
@MainActor
final class ReviewPromptController: ObservableObject {
    private let defaults: UserDefaults
    private let version: String

    init(defaults: UserDefaults = .standard,
         version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0") {
        self.defaults = defaults
        self.version = version
    }

    private var storageKey: String { "tiq.review.requested.\(version)" }

    var alreadyRequested: Bool { defaults.bool(forKey: storageKey) }

    func requestIfAppropriate(newBestScore: Bool, isPerfectRound: Bool, completedRounds: Int) {
        guard ReviewPromptPolicy.shouldRequest(newBestScore: newBestScore,
                                               isPerfectRound: isPerfectRound,
                                               completedRounds: completedRounds,
                                               alreadyRequested: alreadyRequested),
              let scene = UIApplication.shared.connectedScenes
                  .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
        defaults.set(true, forKey: storageKey)
    }
}
