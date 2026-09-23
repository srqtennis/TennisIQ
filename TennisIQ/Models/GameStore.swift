import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var questions: [Question] = []
    @Published private(set) var bankVersion = 0
    @Published private(set) var progression: Progression
    @Published private(set) var recentRounds: [RoundSummary]
    private let progressKey = "tiq.progress.v1"
    private let roundsKey = "tiq.rounds.v1"
    @Published var bestScore: Int
    @Published var sessionsPlayed: Int
    @Published var bestStreak: Int

    init() {
        let decoder = JSONDecoder()
        progression = UserDefaults.standard.data(forKey: "tiq.progress.v1")
            .flatMap { try? decoder.decode(Progression.self, from: $0) } ?? Progression()
        recentRounds = UserDefaults.standard.data(forKey: "tiq.rounds.v1")
            .flatMap { try? decoder.decode([RoundSummary].self, from: $0) } ?? []
        // The legacy tiq.best mixed scoring modes, even for values below 100.
        // Preserve it untouched; start a separately attributable rally record.
        bestScore = UserDefaults.standard.integer(forKey: "tiq.best.rally")
        sessionsPlayed = UserDefaults.standard.integer(forKey: "tiq.played")
        bestStreak = UserDefaults.standard.integer(forKey: "tiq.streak")
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            questions = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(QuestionBankFile.self, from: data)
            questions = file.questions
            bankVersion = file.version
        } catch {
            print("Question bank failed: \(error)")
            questions = []
        }
    }

    func filtered(category: String?, difficulty: String?) -> [Question] {
        questions.filter { q in
            (category == nil || q.category == category) &&
            (difficulty == nil || q.difficulty == difficulty)
        }
    }

    func record(_ summary: RoundSummary, answers: [AnswerRecord]) {
        let before = progression.completedRounds
        progression.record(summary, answers: answers)
        guard progression.completedRounds > before else { return }
        recentRounds.insert(summary, at: 0)
        recentRounds = Array(recentRounds.prefix(20))
        if let data = try? JSONEncoder().encode(progression) { UserDefaults.standard.set(data, forKey: progressKey) }
        if let data = try? JSONEncoder().encode(recentRounds) { UserDefaults.standard.set(data, forKey: roundsKey) }
        record(sessionScore: summary.points, streak: summary.bestStreak, mode: summary.mode)
    }

    func placementDeck() -> [Question] {
        ["rookie", "club", "tour"].flatMap { level in
            let pool = questions.filter { $0.difficulty == level }
            let unseen = pool.filter { !progression.seenQuestionIDs.contains($0.id) }.shuffled()
            let seen = pool.filter { progression.seenQuestionIDs.contains($0.id) }.shuffled()
            return Array((unseen + seen).prefix(10))
        }.shuffled()
    }

    func record(sessionScore: Int, streak: Int, mode: String = "rally") {
        sessionsPlayed += 1
        if mode == "rally", sessionScore > bestScore { bestScore = sessionScore }
        if streak > bestStreak { bestStreak = streak }
        UserDefaults.standard.set(bestScore, forKey: "tiq.best.rally")
        UserDefaults.standard.set(sessionsPlayed, forKey: "tiq.played")
        UserDefaults.standard.set(bestStreak, forKey: "tiq.streak")
    }
}
