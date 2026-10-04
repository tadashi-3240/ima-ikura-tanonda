import Foundation

/// Reads/writes dictionary JSON via App Group. No correction engine in milestone 1.
struct DictionaryStore {
    private let defaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = AppGroupConstants.sharedDefaults) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadEntries() -> [DictionaryEntry] {
        guard let defaults,
              let data = defaults.data(forKey: AppGroupConstants.dictionaryKey) else {
            return []
        }
        return (try? decoder.decode([DictionaryEntry].self, from: data)) ?? []
    }

    func saveEntries(_ entries: [DictionaryEntry]) {
        guard let defaults,
              let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: AppGroupConstants.dictionaryKey)
    }

    /// Seed placeholder for later Kaneko → 金古 work. Call from host when empty (optional).
    func seedSampleIfEmpty() {
        var entries = loadEntries()
        guard entries.isEmpty else { return }
        entries.append(DictionaryEntry(from: "Kaneko", to: "金古"))
        entries.append(DictionaryEntry(from: "かねこ", to: "金古"))
        saveEntries(entries)
    }
}
