import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var store: GameStore
    @State private var category = "all"
    @State private var difficulty = "all"

    private var categories: [String] { Set(store.questions.map(\.category)).sorted() }
    private var selection: [Question] {
        store.filtered(category: category == "all" ? nil : category,
                       difficulty: difficulty == "all" ? nil : difficulty)
    }

    var body: some View {
        Form {
            Section("Choose your practice") {
                Picker("Topic", selection: $category) {
                    Text("All topics").tag("all")
                    ForEach(categories, id: \.self) { key in
                        Text(store.questions.first(where: { $0.category == key })?.categoryLabel ?? key).tag(key)
                    }
                }
                Picker("Difficulty", selection: $difficulty) {
                    Text("All levels").tag("all")
                    Text("Rookie").tag("rookie")
                    Text("Club").tag("club")
                    Text("Tour").tag("tour")
                }
                Text("\(selection.count) questions available. Practice up to ten at a time, without a clock.")
                    .foregroundStyle(.secondary)
            }
            Section {
                NavigationLink(value: Route.quiz(QuizConfig(mode: "practice", count: min(10, selection.count), timed: false, category: category == "all" ? nil : category, difficulty: difficulty == "all" ? nil : difficulty))) {
                    Text("Start practice")
                }
                .disabled(selection.isEmpty)
                .accessibilityIdentifier("start-practice")
            }
        }
        .navigationTitle("Practice")
    }
}
