import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var purchases: PurchaseStore
    @State private var showUnlock = false
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image("BrandMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .accessibilityHidden(true)
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
                    subtitle: "Free forever. Ten mixed questions, with explanations.",
                    identifier: "daily-rally",
                    tint: Color(red: 0.89, green: 0.76, blue: 0.42)
                ) {
                    path.append(Route.quiz(QuizConfig(mode: "rally", count: 10, timed: false, category: nil, difficulty: nil)))
                }

                ModeCard(
                    title: "Shot Clock",
                    subtitle: "Twenty seconds a question. Timeout loses the point.",
                    identifier: "shot-clock",
                    locked: !purchases.isUnlocked,
                    tint: Color(red: 0.76, green: 0.42, blue: 0.29)
                ) {
                    openPremium(.quiz(QuizConfig(mode: "timed", count: 10, timed: true, category: nil, difficulty: nil)))
                }

                HStack(spacing: 10) {
                    MiniCard(title: "Library", subtitle: "\(store.questions.count) questions", identifier: "library", locked: !purchases.isUnlocked) {
                        openPremium(.library)
                    }
                    MiniCard(title: "Practice", subtitle: "Choose topic and level", identifier: "practice", locked: !purchases.isUnlocked) {
                        openPremium(.practice)
                    }
                }

                HStack(spacing: 10) {
                    MiniCard(title: "My IQ", subtitle: purchases.isUnlocked ? "\(store.progression.rating) · \(store.progression.placementLabel)" : "Rating & earned badges", identifier: "progress", locked: !purchases.isUnlocked) { openPremium(.progress) }
                    MiniCard(title: "Challenge", subtitle: "Play the same ten", identifier: "challenge", locked: !purchases.isUnlocked) { openPremium(.challenge) }
                }

                if purchases.isUnlocked {
                    Label("Full game unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.secondary)
                } else {
                    Button("Unlock Tennis IQ") { showUnlock = true }
                        .accessibilityIdentifier("show-unlock")
                }

                NavigationLink("About, Support & Privacy") { AboutView() }
                    .font(.subheadline)

                Text("Know the rules. Explore tennis history. Learn from every answer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .background(Color(red: 0.04, green: 0.12, blue: 0.08).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUnlock) { PaywallView() }
    }

    private func openPremium(_ route: Route) {
        if purchases.isUnlocked { path.append(route) } else { showUnlock = true }
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
    var identifier: String = ""
    var locked: Bool = false
    let tint: Color
    let action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            Button(locked ? "Unlock" : "Play", action: action)
                .accessibilityIdentifier(identifier)
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
    var identifier: String = ""
    var locked: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: locked ? "lock.fill" : "chevron.right").font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.09, green: 0.21, blue: 0.14), in: RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityIdentifier(identifier)
    }
}
