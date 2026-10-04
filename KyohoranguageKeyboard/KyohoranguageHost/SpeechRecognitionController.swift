import AVFoundation
import Foundation
import Speech

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

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var sessionId = UUID()

    var displayText: String {
        let live = partialTranscript.isEmpty ? transcript : partialTranscript
        return live.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func prepareAndStart(sessionId: UUID) async {
        self.sessionId = sessionId
        transcript = ""
        partialTranscript = ""
        phase = .requestingPermission

        let micOK = await requestMicrophonePermission()
        guard micOK else {
            phase = .unavailable("マイクの許可が必要です。設定でマイクをオンにしてください。")
            VoiceBridge.markError(sessionId: sessionId, message: "microphone denied")
            return
        }

        let speechOK = await requestSpeechPermission()
        guard speechOK else {
            phase = .unavailable("音声認識の許可が必要です。設定で音声認識をオンにしてください。")
            VoiceBridge.markError(sessionId: sessionId, message: "speech denied")
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            phase = .unavailable("この端末では日本語の音声認識を利用できません。")
            VoiceBridge.markError(sessionId: sessionId, message: "recognizer unavailable")
            return
        }

        do {
            try startEngine(recognizer: speechRecognizer)
            phase = .listening
            VoiceBridge.markListening(sessionId: sessionId)
        } catch {
            phase = .unavailable("音声の開始に失敗しました: \(error.localizedDescription)")
            VoiceBridge.markError(sessionId: sessionId, message: error.localizedDescription)
        }
    }

    func finish() -> String {
        phase = .finishing
        let text = displayText
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

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func startEngine(recognizer: SFSpeechRecognizer) throws {
        stopEngine()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
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
                if error != nil {
                    // Keep whatever text we already have; user can still tap 完了.
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
        recognitionTask?.cancel()
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
