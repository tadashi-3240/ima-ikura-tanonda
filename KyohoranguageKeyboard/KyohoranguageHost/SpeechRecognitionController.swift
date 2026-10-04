import AVFoundation
import Foundation
import Speech
import UIKit

/// Host-only speech recognition using public Speech + AVFoundation APIs.
@MainActor
final class SpeechRecognitionController: ObservableObject {
    enum Phase: Equatable {
        case idle
        case requestingPermission
        case listening
        case finishing
        case unavailable(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var transcript: String = ""
    @Published private(set) var partialTranscript: String = ""
    @Published private(set) var lastErrorHint: String?

    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var sessionId = UUID()
    private var preferOnDevice = false

    var displayText: String {
        let live = partialTranscript.isEmpty ? transcript : partialTranscript
        return live.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func prepareAndStart(sessionId: UUID) async {
        self.sessionId = sessionId
        transcript = ""
        partialTranscript = ""
        lastErrorHint = nil
        preferOnDevice = false
        phase = .requestingPermission

        guard await ensureMicrophonePermission() else { return }
        guard await ensureSpeechPermission() else { return }

        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            failUnavailable("日本語の音声認識を利用できません。ネットワーク接続を確認するか、しばらくしてからもう一度話してください。")
            return
        }

        do {
            try startEngine(recognizer: recognizer, onDevice: false)
            phase = .listening
            VoiceBridge.markListening(sessionId: sessionId)
        } catch {
            // Public API fallback: try on-device recognition when available.
            if recognizer.supportsOnDeviceRecognition {
                do {
                    preferOnDevice = true
                    try startEngine(recognizer: recognizer, onDevice: true)
                    phase = .listening
                    VoiceBridge.markListening(sessionId: sessionId)
                    return
                } catch {
                    failUnavailable("音声の開始に失敗しました。マイクが他のアプリで使われていないか確認してください。")
                    return
                }
            }
            failUnavailable("音声の開始に失敗しました。もう一度お試しください。")
        }
    }

    /// Ends audio and briefly waits for a final transcript (public Speech API).
    func finish() async -> String {
        phase = .finishing
        recognitionRequest?.endAudio()
        recognitionTask?.finish()

        let deadline = Date().addingTimeInterval(1.25)
        while Date() < deadline {
            if !displayText.isEmpty {
                // Allow a short moment for isFinal to arrive.
                try? await Task.sleep(nanoseconds: 250_000_000)
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        let text = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        stopEngine()
        transcript = text
        partialTranscript = ""
        phase = .idle
        return text
    }

    func cancel() {
        stopEngine()
        transcript = ""
        partialTranscript = ""
        phase = .idle
        VoiceBridge.markCancelled(sessionId: sessionId)
    }

    func retryListening() async {
        await prepareAndStart(sessionId: sessionId)
    }

    // MARK: - Permissions

    private func ensureMicrophonePermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            return true
        case .denied:
            failUnavailable("マイクの許可がオフです。iPhoneの「設定」→「協豊ランゲージ」→「マイク」をオンにしてください。")
            return false
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { continuation.resume(returning: $0) }
            }
            if !granted {
                failUnavailable("マイクの許可が必要です。設定でマイクをオンにして、もう一度話してください。")
            }
            return granted
        @unknown default:
            failUnavailable("マイクの状態を確認できません。設定でマイクをオンにしてください。")
            return false
        }
    }

    private func ensureSpeechPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            failUnavailable("音声認識の許可がオフです。iPhoneの「設定」→「協豊ランゲージ」→「音声認識」をオンにしてください。")
            return false
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            if status != .authorized {
                failUnavailable("音声認識の許可が必要です。設定で音声認識をオンにして、もう一度話してください。")
                return false
            }
            return true
        @unknown default:
            failUnavailable("音声認識の状態を確認できません。設定を確認してください。")
            return false
        }
    }

    private func failUnavailable(_ message: String) {
        phase = .unavailable(message)
        lastErrorHint = message
        VoiceBridge.markError(sessionId: sessionId, message: message)
    }

    // MARK: - Engine

    private func startEngine(recognizer: SFSpeechRecognizer, onDevice: Bool) throws {
        stopEngine()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if onDevice, recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        } else {
            request.requiresOnDeviceRecognition = false
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "KyohoranguageSpeech", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "マイク入力の形式を取得できませんでした"
            ])
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.transcript = text
                        self.partialTranscript = ""
                    } else {
                        self.partialTranscript = text
                    }
                }
                if let error {
                    if self.displayText.isEmpty {
                        self.lastErrorHint = "うまく聞き取れませんでした。もう一度話してください。"
                    }
                    _ = error
                    self.stopEngineKeepingText()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func stopEngineKeepingText() {
        recognitionRequest?.endAudio()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func stopEngine() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
