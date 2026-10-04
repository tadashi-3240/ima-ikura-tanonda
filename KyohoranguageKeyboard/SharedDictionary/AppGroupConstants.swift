import Foundation

enum AppGroupConstants {
    /// Shared App Group identifier (must match entitlements for host + keyboard).
    static let suiteName = "group.jp.kyohoranguage.shared"

    /// UserDefaults key for the serialized dictionary JSON (v2 schema).
    static let dictionaryKey = "kyohoranguage.dictionary.entries.v2"

    /// Keyboard preference: dictionary correction enabled.
    static let correctionEnabledKey = "kyohoranguage.keyboard.correctionEnabled"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }
}
