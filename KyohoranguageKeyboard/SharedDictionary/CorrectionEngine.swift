import Foundation

/// Replaces misrecognition candidates with correct words. Longer matches win first.
struct CorrectionEngine {
    struct Rule: Equatable {
        let from: String
        let to: String
    }

    /// Rules sorted by `from` length descending (金子町 before 金子).
    let rules: [Rule]

    init(rules: [Rule]) {
        self.rules = rules
            .filter { !$0.from.isEmpty && $0.from != $0.to }
            .sorted { lhs, rhs in
                if lhs.from.count != rhs.from.count {
                    return lhs.from.count > rhs.from.count
                }
                return lhs.from < rhs.from
            }
    }

    init(entries: [DictionaryEntry]) {
        var built: [Rule] = []
        var claimed = Set<String>()

        for entry in entries {
            let correct = entry.correct.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !correct.isEmpty else { continue }
            for candidate in entry.misrecognitions {
                let from = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !from.isEmpty, from != correct else { continue }
                guard !claimed.contains(from) else { continue }
                claimed.insert(from)
                built.append(Rule(from: from, to: correct))
            }
        }
        self.init(rules: built)
    }

    /// Left-to-right scan; at each position take the longest matching rule.
    func correct(_ text: String) -> String {
        guard !text.isEmpty, !rules.isEmpty else { return text }

        var output = String()
        output.reserveCapacity(text.count)
        var index = text.startIndex

        while index < text.endIndex {
            let remainder = text[index...]
            var didMatch = false

            for rule in rules {
                if remainder.hasPrefix(rule.from) {
                    output.append(rule.to)
                    index = text.index(index, offsetBy: rule.from.count)
                    didMatch = true
                    break
                }
            }

            if !didMatch {
                output.append(text[index])
                index = text.index(after: index)
            }
        }

        return output
    }

    func correct(_ text: String, enabled: Bool) -> String {
        enabled ? correct(text) : text
    }
}
