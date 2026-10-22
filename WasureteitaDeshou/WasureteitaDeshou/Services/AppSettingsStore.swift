import Foundation
import Combine

/// 端末内のユーザー設定。第1段階では起動時の音声自動開始のみ。
@MainActor
final class AppSettingsStore: ObservableObject {
    private enum Keys {
        static let autoStartVoiceOnLaunch = "settings.autoStartVoiceOnLaunch"
    }

    @Published var autoStartVoiceOnLaunch: Bool {
        didSet {
            UserDefaults.standard.set(autoStartVoiceOnLaunch, forKey: Keys.autoStartVoiceOnLaunch)
        }
    }

    init() {
        autoStartVoiceOnLaunch = UserDefaults.standard.bool(forKey: Keys.autoStartVoiceOnLaunch)
    }
}
