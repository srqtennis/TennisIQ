import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published var questions: [Question] = []
    @Published var bestScore: Int
    @Published var sessionsPlayed: Int
    @Published var bestStreak: Int

    init() {
        bestScore = UserDefaults.standard.integer(forKey: "tiq.best")
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

    func record(sessionScore: Int, streak: Int) {
        sessionsPlayed += 1
        if sessionScore > bestScore { bestScore = sessionScore }
        if streak > bestStreak { bestStreak = streak }
        UserDefaults.standard.set(bestScore, forKey: "tiq.best")
        UserDefaults.standard.set(sessionsPlayed, forKey: "tiq.played")
        UserDefaults.standard.set(bestStreak, forKey: "tiq.streak")
    }
}
