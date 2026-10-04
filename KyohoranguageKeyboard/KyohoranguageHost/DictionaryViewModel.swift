import Foundation
import Combine

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var entries: [DictionaryEntry] = []
    @Published var searchText: String = ""
    @Published var statusMessage: String?

    private let store = DictionaryStore()

    var filteredEntries: [DictionaryEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        return entries.filter { entry in
            entry.correct.localizedCaseInsensitiveContains(query)
                || entry.reading.localizedCaseInsensitiveContains(query)
                || entry.misrecognitions.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    func reload() {
        entries = store.seedInitialEntriesIfEmpty()
            .sorted { $0.correct.localizedStandardCompare($1.correct) == .orderedAscending }
    }

    func save(_ entry: DictionaryEntry) {
        var next = entries
        if let index = next.firstIndex(where: { $0.id == entry.id }) {
            next[index] = entry
        } else {
            next.append(entry)
        }
        persist(next, message: "辞書を保存しました")
    }

    func delete(at offsets: IndexSet) {
        let targets = offsets.map { filteredEntries[$0].id }
        let next = entries.filter { !targets.contains($0.id) }
        persist(next, message: "削除しました")
    }

    func delete(_ entry: DictionaryEntry) {
        let next = entries.filter { $0.id != entry.id }
        persist(next, message: "削除しました")
    }

    func resetToSeed() {
        entries = store.resetToInitialEntries()
            .sorted { $0.correct.localizedStandardCompare($1.correct) == .orderedAscending }
        statusMessage = "初期辞書に戻しました（キーボード側も再表示で反映）"
    }

    private func persist(_ next: [DictionaryEntry], message: String) {
        guard store.saveEntries(next) else {
            statusMessage = "保存に失敗しました。App Group とフルアクセスを確認してください。"
            return
        }
        entries = next.sorted { $0.correct.localizedStandardCompare($1.correct) == .orderedAscending }
        statusMessage = message
    }
}
