import Foundation

/// One correction rule (e.g. Kaneko → 金古). Engine not implemented in milestone 1.
struct DictionaryEntry: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    /// Source text as typed / recognized (e.g. "Kaneko", "かねこ").
    var from: String
    /// Replacement text (e.g. "金古").
    var to: String
    var updatedAt: Date

    init(id: UUID = UUID(), from: String, to: String, updatedAt: Date = Date()) {
        self.id = id
        self.from = from
        self.to = to
        self.updatedAt = updatedAt
    }
}
