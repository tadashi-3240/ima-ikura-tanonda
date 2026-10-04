import Foundation

/// One dictionary row: correct word + reading + misrecognition candidates.
struct DictionaryEntry: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    /// 正解語（例: 金古）
    var correct: String
    /// 読み（例: かねこ）
    var reading: String
    /// 誤認識候補（例: 金子, カネコ, かねこ）
    var misrecognitions: [String]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        correct: String,
        reading: String,
        misrecognitions: [String] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.correct = correct
        self.reading = reading
        self.misrecognitions = Self.normalizedList(misrecognitions)
        self.updatedAt = updatedAt
    }

    var displayMisrecognitions: String {
        misrecognitions.joined(separator: "、")
    }

    mutating func setMisrecognitions(fromCommaSeparated text: String) {
        misrecognitions = Self.normalizedList(
            text
                .split(whereSeparator: { $0 == "," || $0 == "、" || $0 == "\n" })
                .map(String.init)
        )
    }

    static func normalizedList(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in values {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            result.append(trimmed)
        }
        return result
    }
}
