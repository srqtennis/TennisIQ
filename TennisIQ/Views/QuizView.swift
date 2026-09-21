import SwiftUI

struct QuizView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let config: QuizConfig

    @State private var deck: [Question] = []
    @State private var index = 0
    @State private var score = 0
    @State private var streak = 0
    @State private var maxStreak = 0
    @State private var picked: Int? = nil
    @State private var seconds = 20
    @State private var finished = false
    @State private var timerOn = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var current: Question? {
        guard index < deck.count else { return nil }
        return deck[index]
    }

    var body: some View {
        Group {
            if finished {
                ResultPane(score: score, total: deck.count, timed: config.timed, onAgain: reset, onHome: { dismiss() })
            } else if let q = current {
                questionPane(q)
            } else {
                ProgressView("Loading hopper…")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.04, green: 0.12, blue: 0.08).ignoresSafeArea())
        .navigationTitle("\(index + 1)/\(max(deck.count, 1))")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if deck.isEmpty { deal() } }
        .onReceive(timer) { _ in
            guard config.timed, !finished, picked == nil, timerOn else { return }
            if seconds <= 1 {
                lock(-1)
            } else {
                seconds -= 1
            }
        }
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
                .font(.title3.weight(.semibold))
                .padding(.vertical, 4)

            ForEach(q.choices.indices, id: \.self) { i in
                Button {
                    lock(i)
                } label: {
                    Text(q.choices[i])
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(choiceColor(q, i), in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(picked != nil)
                .foregroundStyle(.white)
            }

            if picked != nil {
                Text(q.explain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.06, green: 0.15, blue: 0.10), in: RoundedRectangle(cornerRadius: 12))

                Button(index + 1 == deck.count ? "See result" : "Next ball") {
                    advance()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
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
        deck = Array(pool.shuffled().prefix(config.count))
        index = 0
        score = 0
        streak = 0
        maxStreak = 0
        picked = nil
        seconds = 20
        finished = false
        timerOn = config.timed
    }

    func lock(_ choice: Int) {
        guard picked == nil, let q = current else { return }
        picked = choice
        timerOn = false
        if choice == q.answer {
            score += config.timed ? 12 + max(0, seconds) : 10
            streak += 1
            maxStreak = max(maxStreak, streak)
        } else {
            streak = 0
        }
    }

    func advance() {
        if index + 1 >= deck.count {
            store.record(sessionScore: score, streak: maxStreak)
            finished = true
        } else {
            index += 1
            picked = nil
            seconds = 20
            timerOn = config.timed
        }
    }

    func reset() { deal() }
}

struct ResultPane: View {
    let score: Int
    let total: Int
    let timed: Bool
    let onAgain: () -> Void
    let onHome: () -> Void

    var pct: Int {
        let maxPts = total * (timed ? 32 : 10)
        guard maxPts > 0 else { return 0 }
        return Int((Double(score) / Double(maxPts)) * 100)
    }

    var line: String {
        switch pct {
        case 90...: return "Tour brain. Take the chair."
        case 75..<90: return "Club champion. Tight margins."
        case 55..<75: return "Solid league player. Keep drilling."
        default: return "First-ball project. Read the notes and go again."
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tennis IQ").font(.caption).foregroundStyle(.secondary)
            Text("\(pct)").font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color(red: 0.89, green: 0.76, blue: 0.42))
            Text(line).multilineTextAlignment(.center)
            Text("\(score) points earned").font(.caption).foregroundStyle(.secondary)
            Button("Play again", action: onAgain)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
                .foregroundStyle(.black)
            Button("Home", action: onHome)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
