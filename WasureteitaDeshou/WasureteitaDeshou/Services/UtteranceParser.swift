import Foundation

/// 日本語の短い用事文から場所と用事を分ける。厳密な NLP ではない。
enum UtteranceParser {
    static func parse(_ text: String) -> ParsedUtterance {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let split = split(by: "で", in: trimmed), !split.place.isEmpty, !split.task.isEmpty {
            return ParsedUtterance(rawText: trimmed, placePhrase: split.place, taskPhrase: split.task)
        }

        // 「〜に寄って〜」「〜へ行って〜」など
        for connector in ["に寄って", "へ行って", "に行って", "まで行って"] {
            if let split = split(by: connector, in: trimmed), !split.place.isEmpty {
                let task = split.task.isEmpty ? "用事あり" : split.task
                return ParsedUtterance(rawText: trimmed, placePhrase: split.place, taskPhrase: task)
            }
        }

        if let brandSplit = splitByKnownBrand(in: trimmed) {
            return brandSplit
        }

        // 場所が取れない → 地図指定用に用事だけ残す
        return ParsedUtterance(
            rawText: trimmed,
            placePhrase: "",
            taskPhrase: trimmed.isEmpty ? "用事あり" : trimmed
        )
    }

    private static func split(by separator: String, in text: String) -> (place: String, task: String)? {
        guard let range = text.range(of: separator) else { return nil }
        let place = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let task = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (place, task)
    }

    /// 「セブンイレブンで…」のように接続詞なしでも店舗名が含まれる場合
    private static func splitByKnownBrand(in text: String) -> ParsedUtterance? {
        let brands = [
            "セブンイレブン", "セブン−イレブン", "セブン-イレブン", "セブン",
            "ファミリーマート", "ファミマ",
            "ローソン",
            "ミニストップ",
            "デイリーヤマザキ",
            "イオン", "マックスバリュ",
            "コストコ",
            "薬局", "ドラッグストア"
        ]

        for brand in brands {
            guard let range = text.range(of: brand) else { continue }
            let before = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let afterBrand = String(text[range.upperBound...])
            let place: String
            if before.isEmpty {
                place = brand
            } else if before.hasSuffix("の") {
                place = before + brand
            } else {
                place = (before + brand).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            var task = afterBrand
                .trimmingCharacters(in: .whitespacesAndNewlines)
            for prefix in ["で", "に", "へ", "を"] {
                if task.hasPrefix(prefix) {
                    task = String(task.dropFirst(prefix.count))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
            if task.isEmpty { task = "用事あり" }
            return ParsedUtterance(rawText: text, placePhrase: place, taskPhrase: task)
        }
        return nil
    }
}
