import Foundation

nonisolated struct AnswerRecord: Codable, Equatable {
    let questionID: String
    let category: String
    let difficulty: String
    let isCorrect: Bool
}

nonisolated struct RoundSummary: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let mode: String
    let correct: Int
    let total: Int
    let points: Int
    let bestStreak: Int
    let questionIDs: [String]

    init(id: UUID = UUID(), date: Date = Date(), mode: String, correct: Int,
         total: Int, points: Int, bestStreak: Int, questionIDs: [String]) {
        self.id = id
        self.date = date
        self.mode = mode
        self.correct = correct
        self.total = total
        self.points = points
        self.bestStreak = bestStreak
        self.questionIDs = questionIDs
    }
}

nonisolated struct EarnedBadge: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let isEarned: Bool
}

/// A quiz-knowledge estimate, not a measure of intelligence or tennis playing ability.
/// Only the first submitted answer to each question contributes to the rating and
/// category counts. Repeated practice still counts toward activity totals.
nonisolated struct Progression: Codable, Equatable {
    static let categories = ["court", "equipment", "scoring", "rules", "history",
                             "slams", "lingo", "strategy", "tour"]

    private(set) var completedRounds = 0
    private(set) var totalAnswered = 0
    private(set) var totalCorrect = 0
    private(set) var seenQuestionIDs: Set<String> = []
    private(set) var recentFirstAttempts: [AnswerRecord] = []
    private(set) var completedModes: Set<String> = []
    private(set) var categoryAnsweredCounts: [String: Int] = [:]
    private(set) var categoryCorrectCounts: [String: Int] = [:]
    private(set) var unlockedBadgeIDs: Set<String> = []
    private var recordedRoundIDs: Set<UUID> = []

    init() {}

    /// Smoothed percent correct over the latest 100 distinct first attempts,
    /// rounded down. Five correct and five incorrect prior answers avoid extremes
    /// from a very small sample; an empty record therefore starts at 50.
    var rating: Int {
        let correct = recentFirstAttempts.filter(\.isCorrect).count
        return (correct + 5) * 100 / (recentFirstAttempts.count + 10)
    }

    var isProvisional: Bool { seenQuestionIDs.count < 30 }

    var placementLabel: String {
        guard !isProvisional else { return "Provisional" }
        switch rating {
        case ..<40: return "Learning"
        case 40..<60: return "Building"
        case 60..<80: return "Confident"
        default: return "Expert"
        }
    }

    /// Includes locked badges so the interface can display the next milestones.
    var badges: [EarnedBadge] {
        [
            badge("first-round", "First Round", "Complete one quiz round.", "flag.checkered"),
            badge("perfect-round", "Perfect Round", "Answer every question correctly in a round of at least ten questions.", "checkmark.seal.fill"),
            badge("10-rounds", "Regular Practice", "Complete ten quiz rounds.", "repeat"),
            badge("100-unique", "Century", "Answer one hundred different questions.", "100.circle.fill"),
            badge("streak10", "Ten in a Row", "Get ten consecutive answers correct within a round.", "flame.fill"),
            badge("all-nine-categories-firstcorrect", "All-Court Knowledge", "Answer a question correctly on its first attempt in all nine categories.", "square.grid.3x3.fill")
        ]
    }

    mutating func record(_ summary: RoundSummary, answers: [AnswerRecord]) {
        guard recordedRoundIDs.insert(summary.id).inserted else { return }
        completedRounds += 1
        completedModes.insert(summary.mode)
        totalAnswered += answers.count
        totalCorrect += answers.filter(\.isCorrect).count

        for answer in answers {
            guard seenQuestionIDs.insert(answer.questionID).inserted else { continue }
            recentFirstAttempts.append(answer)
            categoryAnsweredCounts[answer.category, default: 0] += 1
            if answer.isCorrect {
                categoryCorrectCounts[answer.category, default: 0] += 1
            }
        }
        if recentFirstAttempts.count > 100 {
            recentFirstAttempts.removeFirst(recentFirstAttempts.count - 100)
        }

        unlockedBadgeIDs.insert("first-round")
        // Evaluate achievement evidence from the answers, not a potentially
        // inconsistent display summary. Once earned, badges never disappear.
        if answers.count >= 10, answers.allSatisfy(\.isCorrect) {
            unlockedBadgeIDs.insert("perfect-round")
        }
        if completedRounds >= 10 { unlockedBadgeIDs.insert("10-rounds") }
        if seenQuestionIDs.count >= 100 { unlockedBadgeIDs.insert("100-unique") }
        var streak = 0
        for answer in answers {
            streak = answer.isCorrect ? streak + 1 : 0
            if streak >= 10 { unlockedBadgeIDs.insert("streak10") }
        }
        if Self.categories.allSatisfy({ categoryCorrectCounts[$0, default: 0] > 0 }) {
            unlockedBadgeIDs.insert("all-nine-categories-firstcorrect")
        }
    }

    private func badge(_ id: String, _ title: String, _ detail: String, _ symbol: String) -> EarnedBadge {
        EarnedBadge(id: id, title: title, detail: detail, symbol: symbol,
                    isEarned: unlockedBadgeIDs.contains(id))
    }
}
