import Foundation
import Combine

/// 予定の端末内永続化（ログイン不要）。追加・更新・削除で位置監視を同期する。
@MainActor
final class ReminderStore: ObservableObject {
    private enum Keys {
        static let reminders = "reminders.v1"
    }

    @Published private(set) var reminders: [Reminder] = []

    private let locationMonitor: LocationMonitor

    init(locationMonitor: LocationMonitor) {
        self.locationMonitor = locationMonitor
        load()
        locationMonitor.sync(reminders: reminders)
    }

    func add(_ reminder: Reminder) {
        reminders.insert(reminder, at: 0)
        persistAndSync()
    }

    func update(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index] = reminder
        persistAndSync()
    }

    func delete(id: UUID) {
        reminders.removeAll { $0.id == id }
        locationMonitor.stopMonitoring(id: id)
        persistAndSync()
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { reminders[$0].id }
        reminders.remove(atOffsets: offsets)
        for id in ids {
            locationMonitor.stopMonitoring(id: id)
        }
        persistAndSync()
    }

    /// 手動完了（第4段階の履歴保存はしない。一覧から外すだけ）
    func complete(id: UUID) {
        delete(id: id)
    }

    func resyncMonitoring() {
        locationMonitor.sync(reminders: reminders)
    }

    private func persistAndSync() {
        save()
        locationMonitor.sync(reminders: reminders)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Keys.reminders) else {
            reminders = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([Reminder].self, from: data)
            reminders = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            reminders = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(reminders)
            UserDefaults.standard.set(data, forKey: Keys.reminders)
        } catch {
            // 端末内保存失敗時はメモリ上の一覧を維持
        }
    }
}
