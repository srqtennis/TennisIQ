import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: GameStore
    @State private var path = NavigationPath()

    var groups: [(String, [Question])] {
        Dictionary(grouping: store.questions, by: \.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            ForEach(groups, id: \.0) { cat, items in
                NavigationLink {
                    CategoryDetail(title: items.first?.categoryLabel ?? cat, items: items)
                } label: {
                    HStack {
                        Text(items.first?.categoryLabel ?? cat)
                        Spacer()
                        Text("\(items.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.04, green: 0.12, blue: 0.08))
        .navigationTitle("Library")
    }
}

struct CategoryDetail: View {
    let title: String
    let items: [Question]

    var body: some View {
        List(items) { q in
            VStack(alignment: .leading, spacing: 6) {
                Text(q.difficultyLabel.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(q.question).font(.headline)
                Text(q.choices[q.answer])
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.89, green: 0.76, blue: 0.42))
                Text(q.explain)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.04, green: 0.12, blue: 0.08))
        .navigationTitle(title)
    }
}
