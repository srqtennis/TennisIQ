import SwiftUI

struct PlayerProgressView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        List {
            Section("Your local Tennis IQ") {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(store.progression.rating)").font(.system(size: 54, weight: .bold))
                        .accessibilityIdentifier("knowledge-rating")
                    Text("/ 100 · \(store.progression.placementLabel)")
                }
                Text("\(store.progression.seenQuestionIDs.count) distinct questions answered")
                    .accessibilityIdentifier("rated-question-count")
                Text(store.progression.isProvisional ? "Provisional until you complete 30 distinct questions. Take placement or keep playing rounds." : "Based on your latest 100 first attempts at distinct questions. Replaying a familiar question does not boost this rating.")
                Text("A personal quiz-knowledge score, not psychological IQ or a tennis playing rating. No comparison with other players is implied.")
                    .font(.footnote).foregroundStyle(.secondary)
                NavigationLink("Take placement") { PlacementView() }
                    .accessibilityIdentifier("take-placement")
            }
            Section("Earned badges") {
                ForEach(store.progression.badges) { badge in
                    HStack {
                        Image(systemName: badge.isEarned ? badge.symbol : "lock.fill")
                            .foregroundStyle(badge.isEarned ? Color.yellow : Color.secondary)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text(badge.title).font(.headline)
                            Text(badge.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if badge.isEarned { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(badge.title). \(badge.isEarned ? "Earned" : "Not earned"). \(badge.detail)")
                    .accessibilityIdentifier("badge-\(badge.id)")
                }
            }
            Section("Recent rounds") {
                if store.recentRounds.isEmpty { Text("Complete a round to start your record.") }
                ForEach(store.recentRounds) { round in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(round.mode.capitalized)
                            Text(round.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(round.correct)/\(round.total)")
                    }
                }
            }
        }
        .navigationTitle("My IQ")
    }
}

struct PlacementView: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Find your starting point").font(.largeTitle.bold())
            Text("Thirty questions: ten each at Rookie, Club and Tour difficulty. No timer. Finish the round to save your placement and earn progress.")
            Text("We prioritize questions you haven’t answered. Your first 30 distinct answers establish your baseline; later first attempts continue to update it. This measures tennis knowledge, not playing ability.")
                .foregroundStyle(.secondary)
            NavigationLink {
                QuizView(config: QuizConfig(mode: "placement", count: 30, timed: false, category: nil, difficulty: nil, questionIDs: store.placementDeck().map(\.id)))
            } label: {
                Text("Start placement")
            }
            .buttonStyle(.borderedProminent).foregroundStyle(.black)
            .accessibilityIdentifier("start-placement")
            Spacer()
        }
        .padding(20)
        }
        .navigationTitle("Placement")
    }
}
