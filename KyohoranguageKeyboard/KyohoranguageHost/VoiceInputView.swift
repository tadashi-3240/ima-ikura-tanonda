import SwiftUI
import UIKit

/// Full-screen voice UI — primary path for speech (host-first).
struct VoiceInputView: View {
    let sessionId: UUID
    var onFinished: () -> Void

    @StateObject private var speech = SpeechRecognitionController()
    private let store = DictionaryStore()
    @State private var didAutoStart = false
    @State private var finishedMessage: String?
    @State private var finishedText: String?
    @State private var errorMessage: String?
    @State private var isCompleting = false

    private var correctionEnabled: Bool {
        store.isCorrectionEnabled()
    }

    private var correctedPreview: String {
        store.makeEngine().correct(speech.displayText, enabled: correctionEnabled)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("音声入力")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            statusBanner

            VStack(alignment: .leading, spacing: 10) {
                Text("認識中")
                    .font(.title2.weight(.semibold))
                Text(displayPrimaryText)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(displayPrimaryTextHasContent ? .primary : .secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if correctionEnabled, displayPrimaryTextHasContent {
                    Text("補正後プレビュー")
                        .font(.title3.weight(.semibold))
                    Text(displayCorrectedText)
                        .font(.system(size: 26, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let finishedMessage {
                Text(finishedMessage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            Spacer(minLength: 8)

            if finishedText != nil {
                Button {
                    onFinished()
                } label: {
                    Text("メモに戻る")
                        .font(.system(size: 32, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .buttonStyle(.borderedProminent)

                Text("協豊キーボードを出したまま戻ると、文字が入ります。入らなければ長押し→ペースト。")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Button {
                    Task { await complete() }
                } label: {
                    Text(isCompleting ? "処理中…" : "完了")
                        .font(.system(size: 32, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCompleting || speech.phase == .requestingPermission)

                if case .unavailable = speech.phase {
                    Button("もう一度話す") {
                        errorMessage = nil
                        finishedMessage = nil
                        finishedText = nil
                        Task { await speech.retryListening() }
                    }
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
                }

                Button("やめる") {
                    speech.cancel()
                    onFinished()
                }
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(20)
        .task { await autoStartIfNeeded() }
        .onAppear { Task { await autoStartIfNeeded() } }
    }

    private var displayPrimaryText: String {
        if let finishedText, !finishedText.isEmpty {
            // Show raw when finished if available from bridge.
            let payload = VoiceBridge.load()
            if !payload.rawText.isEmpty { return payload.rawText }
            return finishedText
        }
        return speech.displayText.isEmpty ? "（まだ聞こえていません）" : speech.displayText
    }

    private var displayPrimaryTextHasContent: Bool {
        if finishedText != nil { return true }
        return !speech.displayText.isEmpty
    }

    private var displayCorrectedText: String {
        if let finishedText, !finishedText.isEmpty {
            return finishedText
        }
        return correctedPreview
    }

    private func autoStartIfNeeded() async {
        guard !didAutoStart else { return }
        didAutoStart = true
        _ = store.seedInitialEntriesIfEmpty()
        // Small yield so the cover animation finishes before the mic permission sheet.
        try? await Task.sleep(nanoseconds: 200_000_000)
        await speech.prepareAndStart(sessionId: sessionId)
    }

    @ViewBuilder
    private var statusBanner: some View {
        if finishedText != nil {
            Label("できました", systemImage: "checkmark.circle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.green)
        } else {
            switch speech.phase {
            case .listening:
                Label("話してください", systemImage: "mic.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.red)
            case .requestingPermission:
                Text("マイクと音声認識の許可を確認しています…")
                    .font(.title3)
            case .finishing:
                Text("文字にしています…")
                    .font(.title3)
            case .unavailable(let message):
                Text(message)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            case .idle:
                if finishedMessage == nil, errorMessage == nil {
                    Text("準備中…")
                        .font(.title3)
                }
            }
        }
    }

    private func complete() async {
        isCompleting = true
        defer { isCompleting = false }

        let raw = await speech.finish()
        if raw.isEmpty {
            let hint = speech.lastErrorHint
                ?? "言葉を認識できませんでした。マイク許可・音声認識許可を確認し、もう一度はっきり話してください。"
            errorMessage = hint
            finishedMessage = nil
            finishedText = nil
            VoiceBridge.markError(sessionId: sessionId, message: hint)
            // Restart listening so user can try again without leaving.
            await speech.retryListening()
            return
        }

        let engine = store.makeEngine()
        let corrected = engine.correct(raw, enabled: store.isCorrectionEnabled())
        VoiceBridge.markReady(sessionId: sessionId, rawText: raw, correctedText: corrected)

        // Clipboard backup (public API) if keyboard insert is delayed.
        let forPaste = store.isCorrectionEnabled() ? corrected : raw
        UIPasteboard.general.string = forPaste
        VoiceBridge.saveClipboardText(forPaste)

        errorMessage = nil
        finishedText = forPaste
        finishedMessage = "コピーしました。\nメモに戻ると、協豊キーボードが文字を入れます。"
    }
}
