import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: GameStore
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(red: 0.83, green: 0.88, blue: 0.34))
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tennis IQ")
                            .font(.title2.weight(.bold))
                        Text("Know the court. Win the argument.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                HStack(spacing: 8) {
                    StatTile(value: "\(store.bestScore)", label: "Best rally")
                    StatTile(value: "\(store.sessionsPlayed)", label: "Sessions")
                    StatTile(value: "\(store.bestStreak)", label: "Best streak")
                }

                ModeCard(
                    title: "Daily Rally",
                    subtitle: "Ten mixed questions. Explanations after every ball.",
                    tint: Color(red: 0.89, green: 0.76, blue: 0.42)
                ) {
                    path.append(Route.quiz(QuizConfig(mode: "rally", count: 10, timed: false, category: nil, difficulty: nil)))
                }

                ModeCard(
                    title: "Shot Clock",
                    subtitle: "Twenty seconds a question. Timeout loses the point.",
                    tint: Color(red: 0.76, green: 0.42, blue: 0.29)
                ) {
                    path.append(Route.quiz(QuizConfig(mode: "timed", count: 10, timed: true, category: nil, difficulty: nil)))
                }

                HStack(spacing: 10) {
                    MiniCard(title: "Library", subtitle: "\(store.questions.count) questions") {
                        path.append(Route.library)
                    }
                    MiniCard(title: "Tour drill", subtitle: "Hardest balls only") {
                        path.append(Route.quiz(QuizConfig(mode: "practice", count: 8, timed: false, category: nil, difficulty: "tour")))
                    }
                }

                Text("ITF court and scoring. Records labelled by era. Open the web build on your iPhone and Add to Home Screen while you wait for TestFlight.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .background(Color(red: 0.04, green: 0.12, blue: 0.08).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(Color(red: 0.89, green: 0.76, blue: 0.42))
            Text(label.uppercased()).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(red: 0.09, green: 0.21, blue: 0.14), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ModeCard: View {
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            Button("Play", action: action)
                .buttonStyle(.borderedProminent)
                .tint(tint)
                .foregroundStyle(.black)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.09, green: 0.21, blue: 0.14), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct MiniCard: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.09, green: 0.21, blue: 0.14), in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
