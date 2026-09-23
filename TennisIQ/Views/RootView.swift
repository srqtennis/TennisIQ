import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var purchases: PurchaseStore
    @State private var path = NavigationPath()
    @State private var incomingChallenge: IncomingChallenge?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .quiz(let config):
                        if config.mode == "rally" || purchases.isUnlocked {
                            QuizView(config: config)
                        } else { PaywallView(dismissOnUnlock: false) }
                    case .library:
                        if purchases.isUnlocked { LibraryView() } else { PaywallView(dismissOnUnlock: false) }
                    case .practice:
                        if purchases.isUnlocked { PracticeView() } else { PaywallView(dismissOnUnlock: false) }
                    case .progress:
                        if purchases.isUnlocked { PlayerProgressView() } else { PaywallView(dismissOnUnlock: false) }
                    case .challenge:
                        if purchases.isUnlocked { ChallengeView() } else { PaywallView(dismissOnUnlock: false) }
                    }
                }
        }
        .sheet(item: $incomingChallenge) { incoming in
            NavigationStack {
                if purchases.isUnlocked { ChallengeView(initialLink: incoming.url.absoluteString) }
                else { PaywallView(dismissOnUnlock: false) }
            }
        }
        .onOpenURL { url in
            incomingChallenge = IncomingChallenge(url: url)
        }
        .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
    }
}

enum Route: Hashable {
    case quiz(QuizConfig)
    case library
    case practice
    case progress
    case challenge
}

struct QuizConfig: Hashable {
    var mode: String
    var count: Int
    var timed: Bool
    var category: String?
    var difficulty: String?
    var questionIDs: [String]? = nil
}

private struct IncomingChallenge: Identifiable {
    let id = UUID()
    let url: URL
}
