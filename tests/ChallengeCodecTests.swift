import Foundation

@main
struct ChallengeCodecTests {
    static func main() throws {
        let questions = (0..<10).map {
            Question(id: "q\($0)", category: "rules", difficulty: "rookie",
                     question: "Question \($0)?", choices: ["One", "Two", "Three", "Four"],
                     answer: $0 % 4, explain: "Explanation \($0).", tags: nil)
        }
        let url = try ChallengeCodec.make(questions: questions, bankVersion: 7)
        let text = url.absoluteString
        let decoded = try ChallengeCodec.decode(text, availableQuestions: questions.reversed(), bankVersion: 7)
        precondition(decoded == questions, "Round trip must preserve challenge order")
        let repeated = try ChallengeCodec.make(questions: questions, bankVersion: 7)
        precondition(repeated == url)
        let slash = text.replacingOccurrences(of: "challenge#", with: "challenge/#")
        let decodedSlash = try ChallengeCodec.decode(slash, availableQuestions: questions, bankVersion: 7)
        precondition(decodedSlash == questions)

        var assertions = 3
        func rejects(_ link: String, bank: [Question]? = nil, version: Int = 7) {
            do {
                _ = try ChallengeCodec.decode(link, availableQuestions: bank ?? questions, bankVersion: version)
                fatalError("Accepted invalid challenge")
            } catch {
                precondition(error is ChallengeError)
                precondition(!(error.localizedDescription.isEmpty))
                assertions += 1
            }
        }
        func mutate(_ change: (inout [String: Any]) -> Void) throws -> String {
            var encoded = text.split(separator: "#")[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            encoded += String(repeating: "=", count: (4 - encoded.count % 4) % 4)
            var object = try JSONSerialization.jsonObject(with: Data(base64Encoded: encoded)!) as! [String: Any]
            precondition(Set(object.keys) == ["version", "bankVersion", "questionIDs", "fingerprint"])
            change(&object)
            let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            return "tennisiq://challenge#" + data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        }
        rejects(try mutate { $0["version"] = 2 })
        rejects(try mutate { $0.removeValue(forKey: "version") })
        rejects(text, version: 8)
        rejects(try mutate { $0["bankVersion"] = 8 })
        rejects(try mutate { $0["questionIDs"] = Array(repeating: "q0", count: 10) })
        rejects(try mutate { $0["questionIDs"] = (0..<9).map { "q\($0)" } })
        rejects(try mutate { $0["questionIDs"] = (1...10).map { "q\($0)" } })
        rejects(try mutate { $0["questionIDs"] = Array(questions.map(\.id).reversed()) })
        rejects(try mutate { $0["fingerprint"] = String(repeating: "0", count: 64) })
        rejects(text, bank: Array(questions.dropLast()))
        rejects(text, bank: questions + [questions[0]])
        var changed = questions
        changed[0] = Question(id: "q0", category: "rules", difficulty: "rookie", question: "Changed", choices: questions[0].choices, answer: 0, explain: "Explanation 0.", tags: nil)
        rejects(text, bank: changed)
        for bad in [String(repeating: "x", count: 8_193), String(text.dropLast()), "not a URL", "https://challenge#abc", "tennisiq://other#abc", "tennisiq://user@challenge#abc", "tennisiq://challenge:80#abc", "tennisiq://challenge?query#abc", "tennisiq://challenge/path#abc", "tennisiq://challenge#%61", "tennisiq://challenge#====", "tennisiq://challenge#", " " + text, String(text.split(separator: "#")[1])] {
            rejects(bad)
        }
        do {
            _ = try ChallengeCodec.make(questions: Array(questions.prefix(9)), bankVersion: 7)
            fatalError("Accepted wrong count")
        } catch { assertions += 1 }
        do {
            _ = try ChallengeCodec.make(questions: Array(repeating: questions[0], count: 10), bankVersion: 7)
            fatalError("Accepted duplicate IDs")
        } catch { assertions += 1 }
        print("Challenge codec: \(assertions) assertions passed")
    }
}
