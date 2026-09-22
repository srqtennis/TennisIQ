import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject var store: GameStore
    @State private var linkText: String
    @State private var deck: [Question] = []
    @State private var shareURL: URL?
    @State private var message: String?
    @State private var validatedLink = ""

    init(initialLink: String = "") { _linkText = State(initialValue: initialLink) }

    var body: some View {
        Form {
            Section("Same ten questions") {
                Text("Create a link for a friend, or paste one you received. The link carries the question set, so it needs no account or server. Both players need Tennis IQ and the permanent unlock.")
                Button("Create a challenge") { create() }
                    .accessibilityIdentifier("create-challenge")
            }
            Section("Open a challenge") {
                TextField("Paste a Tennis IQ challenge link", text: $linkText, axis: .vertical)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("challenge-link-input")
                Button("Check link") { validate() }
                    .accessibilityIdentifier("validate-challenge")
                if let message { Text(message).foregroundStyle(.secondary).accessibilityIdentifier("challenge-message") }
            }
            if !deck.isEmpty {
                Section("Ready to play") {
                    Text("Ten questions, in the same order for both players. No timer. Share your result afterward.")
                    Text(deck[0].question).font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("challenge-first-question")
                    NavigationLink {
                        QuizView(config: QuizConfig(mode: "challenge", count: 10, timed: false, category: nil, difficulty: nil, questionIDs: deck.map(\.id)))
                    } label: { Text("Play challenge") }
                    .accessibilityIdentifier("play-challenge")
                    if let shareURL {
                        ShareLink("Share challenge link", item: shareURL)
                            .accessibilityIdentifier("share-challenge")
                    }
                }
            }
            Section {
                Text("Friendly challenges are not verified competition. Scores stay on each phone; links have no anti-cheat or online leaderboard. Matching question-bank versions are required.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Challenge")
        .onChange(of: linkText) { _, value in
            if value != validatedLink { deck = []; shareURL = nil; message = nil }
        }
        .task { if !linkText.isEmpty { validate() } }
    }

    private func create() {
        do {
            let url = try ChallengeCodec.make(questions: Array(store.questions.shuffled().prefix(10)), bankVersion: store.bankVersion)
            linkText = url.absoluteString
            validate()
        } catch { message = error.localizedDescription }
    }

    private func validate() {
        do {
            deck = try ChallengeCodec.decode(linkText.trimmingCharacters(in: .whitespacesAndNewlines), availableQuestions: store.questions, bankVersion: store.bankVersion)
            validatedLink = linkText
            shareURL = URL(string: linkText.trimmingCharacters(in: .whitespacesAndNewlines))
            message = "Challenge ready: \(deck.count) questions."
        } catch { deck = []; shareURL = nil; message = error.localizedDescription }
    }
}
