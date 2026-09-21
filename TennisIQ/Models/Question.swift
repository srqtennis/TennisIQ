import Foundation

struct QuestionBankFile: Codable {
    let version: Int
    let title: String
    let source: String
    let questions: [Question]
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let category: String
    let difficulty: String
    let question: String
    let choices: [String]
    let answer: Int
    let explain: String
    let tags: [String]?

    var categoryLabel: String {
        switch category {
        case "court": return "Court"
        case "equipment": return "Gear"
        case "scoring": return "Scoring"
        case "rules": return "Rules"
        case "history": return "History"
        case "slams": return "Slams"
        case "lingo": return "Lingo"
        case "strategy": return "Strategy"
        case "tour": return "Tour"
        default: return category.capitalized
        }
    }

    var difficultyLabel: String {
        switch difficulty {
        case "rookie": return "Rookie"
        case "club": return "Club"
        case "tour": return "Tour"
        default: return difficulty.capitalized
        }
    }
}

enum PlayMode: String {
    case rally, timed, practice
}
