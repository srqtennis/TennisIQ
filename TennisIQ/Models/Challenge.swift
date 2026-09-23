import Foundation
import CryptoKit

struct ChallengePayload: Codable, Equatable {
    var version: Int = 1
    let bankVersion: Int
    let questionIDs: [String]
    let fingerprint: String
}

enum ChallengeError: LocalizedError {
    case malformed
    case tooLong
    case unsupportedVersion
    case invalidQuestionCount
    case duplicateQuestions
    case unknownQuestions
    case bankMismatch

    var errorDescription: String? {
        switch self {
        case .malformed:
            return "This challenge link is incomplete or invalid. Ask your friend to share it again."
        case .tooLong:
            return "This challenge link is too long. Ask your friend for a new link."
        case .unsupportedVersion:
            return "This challenge uses an unsupported format. Update Tennis IQ and try again."
        case .invalidQuestionCount:
            return "A challenge must contain exactly 10 questions."
        case .duplicateQuestions:
            return "This challenge contains repeated questions. Ask your friend for a new link."
        case .unknownQuestions:
            return "Some challenge questions aren’t available in this app. Make sure both players have the same version of Tennis IQ."
        case .bankMismatch:
            return "This challenge uses a different question bank. Make sure both players have the same version of Tennis IQ and share a new link."
        }
    }
}

/// Offline compatibility checking only. The fingerprint is not authentication.
enum ChallengeCodec {
    static let maximumURLLength = 8_192

    static func make(questions: [Question], bankVersion: Int) throws -> URL {
        try validateIDs(questions.map(\.id))
        let payload = ChallengePayload(
            bankVersion: bankVersion,
            questionIDs: questions.map(\.id),
            fingerprint: try fingerprint(questions)
        )
        let encoded = try encoder().encode(payload)
        let text = "tennisiq://challenge#" + base64URL(encoded)
        guard text.utf8.count <= maximumURLLength else { throw ChallengeError.tooLong }
        guard let url = URL(string: text) else { throw ChallengeError.malformed }
        return url
    }

    static func decode(_ text: String, availableQuestions: [Question], bankVersion: Int) throws -> [Question] {
        guard text.utf8.count <= maximumURLLength else { throw ChallengeError.tooLong }
        guard let components = URLComponents(string: text),
              components.scheme == "tennisiq",
              components.host == "challenge",
              components.user == nil, components.password == nil,
              components.port == nil, components.query == nil,
              components.path.isEmpty || components.path == "/",
              let fragment = components.percentEncodedFragment, !fragment.isEmpty,
              text == "tennisiq://challenge" + components.path + "#" + fragment,
              fragment.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 95 })
        else { throw ChallengeError.malformed }

        let base64 = fragment.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = base64 + String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: padded), base64URL(data) == fragment,
              let payload = try? JSONDecoder().decode(ChallengePayload.self, from: data)
        else { throw ChallengeError.malformed }
        guard payload.version == 1 else { throw ChallengeError.unsupportedVersion }
        guard payload.bankVersion == bankVersion else { throw ChallengeError.bankMismatch }
        try validateIDs(payload.questionIDs)
        guard payload.fingerprint.utf8.count == 64,
              payload.fingerprint.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) })
        else { throw ChallengeError.malformed }

        // Avoid Dictionary(uniqueKeysWithValues:) trapping on a malformed bank.
        var lookup: [String: Question] = [:]
        for question in availableQuestions {
            guard lookup.updateValue(question, forKey: question.id) == nil else {
                throw ChallengeError.bankMismatch
            }
        }
        let ordered = try payload.questionIDs.map { id -> Question in
            guard let question = lookup[id] else { throw ChallengeError.unknownQuestions }
            return question
        }
        guard try fingerprint(ordered) == payload.fingerprint else { throw ChallengeError.bankMismatch }
        return ordered
    }

    private static func validateIDs(_ ids: [String]) throws {
        guard ids.count == 10 else { throw ChallengeError.invalidQuestionCount }
        guard !ids.contains(where: \.isEmpty) else { throw ChallengeError.malformed }
        guard Set(ids).count == ids.count else { throw ChallengeError.duplicateQuestions }
    }

    private struct FingerprintQuestion: Encodable {
        let id: String
        let question: String
        let choices: [String]
        let answer: Int
        let explain: String
    }

    private static func fingerprint(_ questions: [Question]) throws -> String {
        let canonical = questions.map {
            FingerprintQuestion(id: $0.id, question: $0.question, choices: $0.choices,
                                answer: $0.answer, explain: $0.explain)
        }
        let data = try encoder().encode(canonical)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
