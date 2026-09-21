import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .quiz(let config):
                        QuizView(config: config)
                    case .library:
                        LibraryView()
                    }
                }
        }
        .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
    }
}

enum Route: Hashable {
    case quiz(QuizConfig)
    case library
}

struct QuizConfig: Hashable {
    var mode: String
    var count: Int
    var timed: Bool
    var category: String?
    var difficulty: String?
}
