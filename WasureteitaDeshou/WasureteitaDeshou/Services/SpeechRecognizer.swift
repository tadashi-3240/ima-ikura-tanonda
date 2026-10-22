import AVFoundation
import Foundation
import Speech

/// マイク入力を日本語の文字に変換する。場所・用事の抽出は行わない（第2段階以降）。
@MainActor
final class SpeechRecognizer: ObservableObject {
    enum PermissionState: Equatable {
        case unknown
        case needsRequest
        case denied
        case restricted
        case granted
    }

    @Published private(set) var transcript: String = ""
    @Published private(set) var isListening: Bool = false
    @Published private(set) var permissionState: PermissionState = .unknown
    @Published private(set) var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var isAvailable: Bool {
        speechRecognizer?.isAvailable == true
    }

    func refreshPermissionState() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micGranted = AVAudioApplication.shared.recordPermission == .granted

        switch speechStatus {
        case .authorized:
            permissionState = micGranted ? .granted : .needsRequest
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        case .notDetermined:
            permissionState = .needsRequest
        @unknown default:
            permissionState = .unknown
        }

        if speechStatus == .authorized && AVAudioApplication.shared.recordPermission == .denied {
            permissionState = .denied
        }
        if speechStatus == .authorized && AVAudioApplication.shared.recordPermission == .undetermined {
            permissionState = .needsRequest
        }
    }

    /// 説明 UI のあとで呼ぶ。マイクと Speech の両方を取得する。
    func requestPermissions() async -> Bool {
        let speechOk = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechOk else {
            refreshPermissionState()
            return false
        }

        let micOk = await AVAudioApplication.requestRecordPermission()
        refreshPermissionState()
        return micOk
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        errorMessage = nil
        refreshPermissionState()

        guard permissionState == .granted else {
            errorMessage = "マイクと音声認識の許可が必要です。"
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "この端末では音声認識を利用できません。"
            return
        }

        stopListening(clearTranscript: false)

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "マイクの準備に失敗しました。"
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening(clearTranscript: false)
                }
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            if transcript.isEmpty {
                transcript = ""
            }
        } catch {
            stopListening(clearTranscript: false)
            errorMessage = "音声入力を開始できませんでした。"
        }
    }

    func stopListening(clearTranscript: Bool = false) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        if clearTranscript {
            transcript = ""
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func clearTranscript() {
        transcript = ""
        errorMessage = nil
    }
}
