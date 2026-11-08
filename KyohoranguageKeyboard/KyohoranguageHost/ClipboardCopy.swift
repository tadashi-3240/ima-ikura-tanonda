import UIKit
import UniformTypeIdentifiers

/// Host clipboard helper — required path for getting text into Notes.
enum ClipboardCopy {
    @discardableResult
    static func copyPlainText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let board = UIPasteboard.general
        board.items = []
        board.string = trimmed
        board.setValue(trimmed, forPasteboardType: "public.utf8-plain-text")
        board.setItems(
            [[
                UTType.utf8PlainText.identifier: trimmed,
                UTType.plainText.identifier: trimmed
            ]],
            options: [.expirationDate: Date().addingTimeInterval(60 * 30)]
        )
        board.string = trimmed

        let readBack = board.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return readBack == trimmed || board.hasStrings
    }
}
