import Foundation

/// 入力文から抜き出した場所フレーズと用事。
struct ParsedUtterance: Equatable, Sendable {
    var rawText: String
    /// 検索に使う場所の言い回し（空なら地図指定へ）
    var placePhrase: String
    var taskPhrase: String

    var hasPlacePhrase: Bool {
        !placePhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
