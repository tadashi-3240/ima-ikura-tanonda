import Foundation

/// Reads/writes dictionary JSON via App Group and seeds the 協豊初期辞書.
struct DictionaryStore {
    private let defaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = AppGroupConstants.sharedDefaults) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadEntries() -> [DictionaryEntry] {
        guard let defaults,
              let data = defaults.data(forKey: AppGroupConstants.dictionaryKey) else {
            return []
        }
        return (try? decoder.decode([DictionaryEntry].self, from: data)) ?? []
    }

    @discardableResult
    func saveEntries(_ entries: [DictionaryEntry]) -> Bool {
        guard let defaults,
              let data = try? encoder.encode(entries) else { return false }
        defaults.set(data, forKey: AppGroupConstants.dictionaryKey)
        defaults.synchronize()
        return true
    }

    /// Inserts the official seed set when the store is empty.
    @discardableResult
    func seedInitialEntriesIfEmpty() -> [DictionaryEntry] {
        var entries = loadEntries()
        if entries.isEmpty {
            entries = Self.initialEntries
            _ = saveEntries(entries)
        }
        return entries
    }

    /// Forces the official seed set (host 「初期辞書に戻す」).
    @discardableResult
    func resetToInitialEntries() -> [DictionaryEntry] {
        let entries = Self.initialEntries
        _ = saveEntries(entries)
        return entries
    }

    func isCorrectionEnabled(default defaultValue: Bool = true) -> Bool {
        guard let defaults else { return defaultValue }
        if defaults.object(forKey: AppGroupConstants.correctionEnabledKey) == nil {
            return defaultValue
        }
        return defaults.bool(forKey: AppGroupConstants.correctionEnabledKey)
    }

    func setCorrectionEnabled(_ enabled: Bool) {
        defaults?.set(enabled, forKey: AppGroupConstants.correctionEnabledKey)
        defaults?.synchronize()
    }

    func makeEngine(from entries: [DictionaryEntry]? = nil) -> CorrectionEngine {
        CorrectionEngine(entries: entries ?? loadEntries())
    }

    /// Official milestone-2 seed (exact product list).
    static let initialEntries: [DictionaryEntry] = [
        DictionaryEntry(
            correct: "金古",
            reading: "かねこ",
            misrecognitions: ["金子", "カネコ", "かねこ"]
        ),
        DictionaryEntry(
            correct: "金古町",
            reading: "かねこまち",
            misrecognitions: ["金子町", "カネコ町"]
        ),
        DictionaryEntry(
            correct: "水江",
            reading: "みずえ",
            misrecognitions: ["瑞江", "水枝", "みずえ"]
        ),
        DictionaryEntry(
            correct: "水江町",
            reading: "みずえちょう",
            misrecognitions: ["瑞江町", "水枝町"]
        ),
        DictionaryEntry(
            correct: "川崎市水江町",
            reading: "かわさきしみずえちょう",
            misrecognitions: ["川崎市瑞江町", "川崎市水枝町"]
        ),
    ]
}
