import Foundation

enum AppGroupConstants {
    /// Shared App Group identifier (must match entitlements for host + keyboard).
    static let suiteName = "group.jp.kyohoranguage.shared"

    /// UserDefaults key for the serialized dictionary JSON (v2 schema).
    static let dictionaryKey = "kyohoranguage.dictionary.entries.v2"

    /// Keyboard preference: dictionary correction enabled.
    static let correctionEnabledKey = "kyohoranguage.keyboard.correctionEnabled"

    /// Shared voice session payload (JSON).
    static let voicePayloadKey = "kyohoranguage.voice.payload.v1"

    /// Last completed voice result (survives session clears; used for paste/insert).
    static let lastVoiceResultKey = "kyohoranguage.voice.lastResult.v1"

    /// Text last copied to the system pasteboard by host voice completion.
    static let lastClipboardTextKey = "kyohoranguage.voice.lastClipboard.v1"

    /// Custom URL scheme for opening the host voice UI from the keyboard.
    static let urlScheme = "kyohoranguage"

    /// Host voice deep link (public URL scheme).
    static let voiceURL = URL(string: "kyohoranguage://voice")!

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }
}
