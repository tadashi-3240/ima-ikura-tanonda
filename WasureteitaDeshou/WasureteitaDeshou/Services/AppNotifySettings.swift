import Foundation
import Combine

/// 通知距離の全体デフォルト（新規予定に適用）。予定ごとの上書きも Reminder に持つ。
@MainActor
final class AppNotifySettings: ObservableObject {
    private enum Keys {
        static let defaultDistance = "settings.defaultNotifyDistanceMeters"
    }

    static let allowedDistances = [300, 500, 1000]

    @Published var defaultNotifyDistanceMeters: Int {
        didSet {
            let clamped = Self.clamp(defaultNotifyDistanceMeters)
            if clamped != defaultNotifyDistanceMeters {
                defaultNotifyDistanceMeters = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Keys.defaultDistance)
        }
    }

    init() {
        let stored = UserDefaults.standard.integer(forKey: Keys.defaultDistance)
        defaultNotifyDistanceMeters = stored == 0 ? 1000 : Self.clamp(stored)
    }

    static func clamp(_ meters: Int) -> Int {
        if allowedDistances.contains(meters) { return meters }
        return 1000
    }
}
