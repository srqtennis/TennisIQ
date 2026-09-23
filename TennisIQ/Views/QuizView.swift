import SwiftUI
import Combine

struct QuizView: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var gameCenter: GameCenterService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let config: QuizConfig

    @State private var deck: [Question] = []
    @State private var roundID = UUID()
    @State private var answers: [AnswerRecord] = []
    @State private var summary: RoundSummary?
    @State private var loadError: String?
    @State private var index = 0
    @State private var score = 0
    @State private var streak = 0
    @State private var maxStreak = 0
    @State private var picked: Int? = nil
    @State private var seconds = 20
    @State private var finished = false
    @State private var newBest = false
    @State private var perfectRound = false
    @State private var deadline: Date?
    @State private var isVisible = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var current: Question? {
        guard index < deck.count else { return nil }
        return deck[index]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if finished, let summary {
                        ResultPane(summary: summary, isNewBest: newBest, isPerfectRound: perfectRound, onAgain: reset, onHome: { dismiss() })
                    } else if let q = current {
                        questionPane(q)
                    } else {
                        VStack(spacing: 16) {
                            Text(loadError ?? "No questions are available. Please reopen the app.")
                            Button("Back") { dismiss() }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .top)
                .id("quiz-top")
            }
            .onChange(of: index) { _, _ in proxy.scrollTo("quiz-top", anchor: .top) }
            .onChange(of: finished) { _, _ in proxy.scrollTo("quiz-top", anchor: .top) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.04, green: 0.12, blue: 0.08).ignoresSafeArea())
        .navigationTitle("\(index + 1)/\(max(deck.count, 1))")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isVisible = true
            if deck.isEmpty { deal() }
            refreshTimer()
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshTimer() }
        }
        .onReceive(timer) { _ in refreshTimer() }
    }

    @ViewBuilder
    func questionPane(_ q: Question) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(q.categoryLabel) · \(q.difficultyLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if config.timed {
                    Text("\(seconds)s").font(.caption.weight(.bold)).foregroundStyle(Color(red: 0.89, green: 0.76, blue: 0.42))
                }
                Text("\(score) pts").font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(index), total: Double(max(deck.count, 1)))
                .tint(Color(red: 0.89, green: 0.76, blue: 0.42))

            Text(q.question)
                .accessibilityIdentifier("quiz-question")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)

            ForEach(q.choices.indices, id: \.self) { i in
                Button {
                    lock(i)
                } label: {
                    Text(q.choices[i])
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(choiceColor(q, i), in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(picked != nil)
                .foregroundStyle(.white)
                .accessibilityLabel(choiceAccessibilityLabel(q, i))
                .accessibilityIdentifier("answer-\(i)")
            }

            if let picked {
                Text(picked == -1 ? "Time’s up" : (picked == q.answer ? "Correct" : "Not quite"))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("Correct answer: \(q.choices[q.answer])")
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(q.explain)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.06, green: 0.15, blue: 0.10), in: RoundedRectangle(cornerRadius: 12))

                Button(index + 1 == deck.count ? "See result" : "Next ball") {
                    advance()
                }
                .accessibilityIdentifier(index + 1 == deck.count ? "finish-quiz" : "next-question")
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
    }

    func choiceAccessibilityLabel(_ q: Question, _ i: Int) -> String {
        guard let picked else { return "Answer \(i + 1): \(q.choices[i])" }
        let status = i == q.answer ? "Correct answer" : (i == picked ? "Your answer, incorrect" : "Incorrect answer")
        return "\(q.choices[i]). \(status)"
    }

    func startClock() {
        seconds = 20
        deadline = config.timed ? Date().addingTimeInterval(20) : nil
    }

    func refreshTimer() {
        guard isVisible, scenePhase == .active, config.timed,
              !finished, picked == nil, let deadline else { return }
        seconds = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
        if seconds == 0 { lock(-1) }
    }

    func choiceColor(_ q: Question, _ i: Int) -> Color {
        guard let picked else {
            return Color(red: 0.07, green: 0.16, blue: 0.11)
        }
        if i == q.answer { return Color.green.opacity(0.28) }
        if i == picked { return Color.red.opacity(0.28) }
        return Color(red: 0.07, green: 0.16, blue: 0.11).opacity(0.5)
    }

    func deal() {
        var pool = store.filtered(category: config.category, difficulty: config.difficulty)
        if pool.count < config.count { pool = store.questions }
        if let ids = config.questionIDs {
            let byID = Dictionary(uniqueKeysWithValues: store.questions.map { ($0.id, $0) })
            deck = ids.compactMap { byID[$0] }
            if deck.count != ids.count || Set(ids).count != ids.count {
                deck = []
                loadError = "This question set is no longer available in this version. Create a new challenge."
            }
        } else {
            deck = Array(pool.shuffled().prefix(config.count))
        }
        roundID = UUID()
        answers = []
        summary = nil
        index = 0
        score = 0
        streak = 0
        maxStreak = 0
        picked = nil
        finished = false
        newBest = false
        perfectRound = false
        startClock()
    }

    func lock(_ choice: Int) {
        guard picked == nil, let q = current else { return }
        let resolvedChoice: Int
        if config.timed, let deadline {
            seconds = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
            resolvedChoice = seconds == 0 ? -1 : choice
        } else {
            resolvedChoice = choice
        }
        picked = resolvedChoice
        answers.append(AnswerRecord(questionID: q.id, category: q.category, difficulty: q.difficulty, isCorrect: resolvedChoice == q.answer))
        deadline = nil
        if resolvedChoice == q.answer {
            score += config.timed ? 12 + max(0, seconds) : 10
            streak += 1
            maxStreak = max(maxStreak, streak)
        } else {
            streak = 0
        }
    }

    func advance() {
        guard !finished, picked != nil, current != nil else { return }
        if index + 1 >= deck.count {
            finished = true
            deadline = nil
            let result = RoundSummary(id: roundID, mode: config.mode, correct: answers.filter(\.isCorrect).count, total: deck.count, points: score, bestStreak: maxStreak, questionIDs: deck.map(\.id))
            let priorBest = store.bestScore
            store.record(result, answers: answers)
            newBest = config.mode == "rally" && result.points > priorBest
            perfectRound = result.total >= 10 && result.correct == result.total
            gameCenter.submitScore(result.points, mode: config.mode)
            gameCenter.reportAchievements(store.progression.unlockedBadgeIDs)
            summary = result
        } else {
            index += 1
            picked = nil
            startClock()
        }
    }

    func reset() { deal() }
}

struct ResultPane: View {
    @EnvironmentObject var store: GameStore
    @EnvironmentObject var purchases: PurchaseStore
    @StateObject private var review = ReviewPromptController()
    let summary: RoundSummary
    var isNewBest = false
    var isPerfectRound = false
    let onAgain: () -> Void
    let onHome: () -> Void

    private var accuracy: Int { summary.total > 0 ? summary.correct * 100 / summary.total : 0 }
    private var challengeURL: URL? {
        guard summary.questionIDs.count == 10 else { return nil }
        let byID = Dictionary(uniqueKeysWithValues: store.questions.map { ($0.id, $0) })
        return try? ChallengeCodec.make(questions: summary.questionIDs.compactMap { byID[$0] }, bankVersion: store.bankVersion)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Tennis IQ").font(.caption).foregroundStyle(.secondary)
            Text("\(accuracy)%").font(.system(size: 64, weight: .bold))
                .accessibilityIdentifier("quiz-results")
                .foregroundStyle(Color(red: 0.89, green: 0.76, blue: 0.42))
            Text("\(summary.correct) of \(summary.total) correct · \(summary.points) points")
            if purchases.isUnlocked {
                Text("Knowledge rating: \(store.progression.rating)/100 · \(store.progression.placementLabel)")
                    .accessibilityIdentifier("result-rating")
                HStack {
                    ForEach(store.progression.badges.filter(\.isEarned)) { badge in
                        Image(systemName: badge.symbol).accessibilityLabel(badge.title)
                            .foregroundStyle(.yellow)
                    }
                }
                ResultShareView(summary: summary, rating: store.progression.rating, isProvisional: store.progression.isProvisional)
                if let challengeURL {
                    ShareLink("Challenge a friend to these ten", item: challengeURL)
                        .accessibilityIdentifier("share-round-challenge")
                }
            } else {
                Text("Your local progress is saved. The permanent unlock includes your knowledge rating, badges and result cards.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Button("Play again", action: onAgain)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
                .foregroundStyle(.black)
            Button("Back", action: onHome)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .onAppear {
            review.requestIfAppropriate(newBestScore: isNewBest,
                                        isPerfectRound: isPerfectRound,
                                        completedRounds: store.progression.completedRounds)
        }
    }
}
