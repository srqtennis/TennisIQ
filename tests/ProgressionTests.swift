import Foundation

// Run from the project root:
// swiftc TennisIQ/Models/Progression.swift tests/ProgressionTests.swift -o /tmp/tennisiq-progression-tests
// /tmp/tennisiq-progression-tests
@main
struct ProgressionTests {
    static var checks = 0

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        checks += 1
        guard condition() else { fatalError("FAILED: \(message)") }
    }

    static func answers(_ count: Int, correct: Int, prefix: String = "q", category: String = "rules") -> [AnswerRecord] {
        (0..<count).map { AnswerRecord(questionID: "\(prefix)-\($0)", category: category,
                                     difficulty: "club", isCorrect: $0 < correct) }
    }

    static func summary(_ answers: [AnswerRecord], mode: String = "rally", id: UUID = UUID()) -> RoundSummary {
        RoundSummary(id: id, date: Date(timeIntervalSince1970: 0), mode: mode,
                     correct: answers.filter(\.isCorrect).count, total: answers.count,
                     points: answers.filter(\.isCorrect).count * 10,
                     bestStreak: 0, questionIDs: answers.map(\.questionID))
    }

    static func main() throws {
        var p = Progression()
        expect(p.rating == 50 && p.isProvisional && p.placementLabel == "Provisional", "empty defaults")
        expect(p.completedRounds == 0 && p.totalAnswered == 0 && p.totalCorrect == 0, "empty totals")
        expect(p.badges.count == 6 && p.badges.allSatisfy { !$0.isEarned }, "badges initially locked")
        expect(Set(p.badges.map(\.id)).count == 6, "stable unique badge identifiers")

        let initial = answers(10, correct: 10)
        let round = summary(initial)
        p.record(round, answers: initial)
        expect(p.rating == 75 && p.seenQuestionIDs.count == 10, "smoothed first round")
        expect(p.completedRounds == 1 && p.totalAnswered == 10 && p.totalCorrect == 10, "first round totals")
        expect(p.unlockedBadgeIDs == ["first-round", "perfect-round", "streak10"], "first achievement batch")
        let beforeDuplicate = p
        p.record(round, answers: answers(50, correct: 0, prefix: "duplicate"))
        expect(p == beforeDuplicate, "same UUID ignores all subsequent payloads")

        let repeats = answers(10, correct: 0)
        p.record(summary(repeats, mode: "practice"), answers: repeats)
        expect(p.rating == 75 && p.seenQuestionIDs.count == 10 && p.recentFirstAttempts.count == 10, "repeat questions do not alter rating")
        expect(p.totalAnswered == 20 && p.totalCorrect == 10 && p.completedRounds == 2, "repeat activity still counted")
        expect(p.categoryAnsweredCounts["rules"] == 10 && p.categoryCorrectCounts["rules"] == 10, "repeat does not inflate category evidence")
        expect(p.completedModes == ["rally", "practice"], "modes captured")
        expect(p.unlockedBadgeIDs.contains("perfect-round"), "badges survive bad rounds")

        var duplicateWithinRound = Progression()
        let wrongThenRight = [AnswerRecord(questionID: "same", category: "rules", difficulty: "club", isCorrect: false),
                              AnswerRecord(questionID: "same", category: "rules", difficulty: "club", isCorrect: true)]
        duplicateWithinRound.record(summary(wrongThenRight), answers: wrongThenRight)
        expect(duplicateWithinRound.rating == 45 && duplicateWithinRound.seenQuestionIDs.count == 1, "first duplicate wins within round")
        expect(duplicateWithinRound.categoryCorrectCounts["rules", default: 0] == 0, "a repeat cannot repair first-attempt category correctness")

        var boundary = Progression()
        let first29 = answers(29, correct: 29)
        boundary.record(summary(first29), answers: first29)
        expect(boundary.isProvisional && boundary.placementLabel == "Provisional", "29 distinct is provisional")
        let thirtieth = answers(1, correct: 1, prefix: "thirtieth")
        boundary.record(summary(thirtieth), answers: thirtieth)
        expect(!boundary.isProvisional && boundary.placementLabel == "Expert", "30 distinct establishes placement")
        for (correct, expectedRating, label) in [(10, 37, "Learning"), (11, 40, "Building"),
                                                  (18, 57, "Building"), (19, 60, "Confident"),
                                                  (26, 77, "Confident"), (27, 80, "Expert")] {
            var placement = Progression()
            let sample = answers(30, correct: correct)
            placement.record(summary(sample), answers: sample)
            expect(placement.rating == expectedRating && placement.placementLabel == label, "placement boundary \(expectedRating)")
        }

        var capped = Progression()
        let hundred = answers(100, correct: 100)
        capped.record(summary(hundred), answers: hundred)
        expect(capped.rating == 95, "upper smoothed bound")
        let newest = answers(1, correct: 0, prefix: "newest")
        capped.record(summary(newest), answers: newest)
        expect(capped.recentFirstAttempts.count == 100 && capped.seenQuestionIDs.count == 101, "window capped; lifetime seen retained")
        expect(capped.recentFirstAttempts.first?.questionID == "q-1" && capped.recentFirstAttempts.last?.questionID == "newest-0", "oldest evicted in input order")
        expect(capped.rating == 94, "window score after eviction")
        let evictedRepeat = [hundred[0]]
        capped.record(summary(evictedRepeat), answers: evictedRepeat)
        expect(capped.recentFirstAttempts.last?.questionID == "newest-0" && capped.rating == 94, "evicted question cannot reenter as first attempt")
        let wrongHundred = answers(100, correct: 0, prefix: "wrong")
        capped.record(summary(wrongHundred), answers: wrongHundred)
        expect(capped.rating == 4 && capped.recentFirstAttempts.count == 100, "lower smoothed bound")
        expect(capped.unlockedBadgeIDs.isSuperset(of: ["100-unique", "perfect-round", "streak10"]), "earned badges persist after full history replacement")
        expect(capped.categoryAnsweredCounts["rules"] == 201 && capped.categoryCorrectCounts["rules"] == 100, "category counts are lifetime first attempts")

        var badges = Progression()
        for (index, category) in Progression.categories.enumerated() {
            let sample = answers(1, correct: 1, prefix: "category-\(index)", category: category)
            badges.record(summary(sample), answers: sample)
        }
        expect(badges.unlockedBadgeIDs.contains("all-nine-categories-firstcorrect"), "all nine categories earned")
        expect(!badges.unlockedBadgeIDs.contains("10-rounds"), "nine rounds below milestone")
        let tenth = answers(1, correct: 0, prefix: "tenth")
        badges.record(summary(tenth), answers: tenth)
        expect(badges.unlockedBadgeIDs.contains("10-rounds"), "ten rounds milestone")
        expect(!badges.unlockedBadgeIDs.contains("streak10"), "streak does not span rounds")

        var forgedSummary = Progression()
        let incorrect = answers(10, correct: 0)
        let inconsistent = RoundSummary(mode: "rally", correct: 10, total: 10, points: 100,
                                        bestStreak: 10, questionIDs: incorrect.map(\.questionID))
        forgedSummary.record(inconsistent, answers: incorrect)
        expect(!forgedSummary.unlockedBadgeIDs.contains("perfect-round") && !forgedSummary.unlockedBadgeIDs.contains("streak10"), "achievement evidence comes from answers")
        expect(forgedSummary.totalCorrect == 0, "activity correctness comes from answers")

        let data = try JSONEncoder().encode(p)
        var restored = try JSONDecoder().decode(Progression.self, from: data)
        expect(restored == p, "progression Codable roundtrip")
        restored.record(round, answers: initial)
        expect(restored == p, "round idempotence survives persistence")
        let persistedBadges = try JSONDecoder().decode(Progression.self, from: JSONEncoder().encode(capped))
        expect(persistedBadges == capped && persistedBadges.badges == capped.badges, "earned badges persist through encoding")
        let restoredSummary = try JSONDecoder().decode(RoundSummary.self, from: JSONEncoder().encode(round))
        expect(restoredSummary == round, "round summary Codable roundtrip")
        let restoredAnswer = try JSONDecoder().decode(AnswerRecord.self, from: JSONEncoder().encode(initial[0]))
        expect(restoredAnswer == initial[0], "answer Codable roundtrip")
        print("Progression: \(checks) checks passed")
    }
}
