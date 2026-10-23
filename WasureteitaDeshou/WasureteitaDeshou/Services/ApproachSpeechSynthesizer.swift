import AVFoundation
import UIKit

/// 接近時の用事文を `AVSpeechSynthesizer` で読み上げる。
///
/// iOS 制約（正直に）:
/// - **フォアグラウンド**: アプリ前面なら日本語 TTS は動作する（設定 ON 時）。
/// - **バックグラウンド／ロック画面**: 領域監視で短く起きても、システムが音声出力を抑えることが多く、
///   自由文の読み上げは **保証できない**。無理押しの `UIBackgroundModes=audio` 迂回はしない。
/// - BG／ロックでは **通知音＋文字** が基本。読み上げは前面での補助。
@MainActor
final class ApproachSpeechSynthesizer: NSObject {
    static let shared = ApproachSpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    private var didConfigureSession = false

    /// 「忘れていたでしょう？○○予定ですよ！」形式。
    static func approachUtterance(task: String) -> String {
        "忘れていたでしょう？\(task)予定ですよ！"
    }

    /// 接近イベント用。設定が OFF なら何もしない。
    func speakApproachIfEnabled(task: String) {
        guard AppNotifySettings.isSpeechEnabledStored else { return }
        speak(Self.approachUtterance(task: task))
    }

    /// 通知の title+body から読み上げ（`willPresent` 用）。設定 OFF なら何もしない。
    func speakNotificationIfEnabled(title: String, body: String) {
        guard AppNotifySettings.isSpeechEnabledStored else { return }
        let text = "\(title)\(body)"
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        speak(text)
    }

    /// 設定画面のテスト。設定の ON/OFF に関わらず一度読む（動作確認用）。
    func speakTest() {
        speak(Self.approachUtterance(task: "テスト"))
    }

    private func speak(_ text: String) {
        prepareAudioSessionIfNeeded()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    /// 最小限のセッション設定。BG 保証のためではない。
    private func prepareAudioSessionIfNeeded() {
        guard !didConfigureSession else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // spokenAudio + duckOthers: 前面での読み上げ向け。BG 継続用の audio モードは付けない。
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
            didConfigureSession = true
        } catch {
            // セッション失敗でも speak は試す（端末状態次第）
            didConfigureSession = false
        }
    }
}
