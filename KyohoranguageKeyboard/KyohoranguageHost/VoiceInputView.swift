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
                Text("いまの言葉")
                    .font(.title2.weight(.semibold))
                Text(speech.displayText.isEmpty ? "（まだ聞こえていません）" : speech.displayText)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(speech.displayText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if correctionEnabled, !speech.displayText.isEmpty {
                    Text("辞書補正後")
                        .font(.title3.weight(.semibold))
                    Text(correctedPreview)
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
        .padding(20)
        .task { await autoStartIfNeeded() }
        .onAppear { Task { await autoStartIfNeeded() } }
    }

    private func autoStartIfNeeded() async {
        guard !didAutoStart else { return }
        didAutoStart = true
        _ = store.seedInitialEntriesIfEmpty()
        await speech.prepareAndStart(sessionId: sessionId)
    }

    @ViewBuilder
    private var statusBanner: some View {
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

    private func complete() async {
        isCompleting = true
        defer { isCompleting = false }

        let raw = await speech.finish()
        if raw.isEmpty {
            let hint = speech.lastErrorHint
                ?? "言葉を認識できませんでした。マイク許可・音声認識許可を確認し、もう一度はっきり話してください。"
            errorMessage = hint
            finishedMessage = nil
            VoiceBridge.markError(sessionId: sessionId, message: hint)
            // Restart listening so user can try again without leaving.
            await speech.retryListening()
            return
        }

        let engine = store.makeEngine()
        let corrected = engine.correct(raw, enabled: store.isCorrectionEnabled())
        VoiceBridge.markReady(sessionId: sessionId, rawText: raw, correctedText: corrected)

        // Clipboard backup (public API) if keyboard insert is delayed.
        UIPasteboard.general.string = store.isCorrectionEnabled() ? corrected : raw

        errorMessage = nil
        finishedMessage = "できました！\nメモなどの元のアプリに戻ると文字が入ります。\n（念のためコピーもしてあります）"

        // No public API to force-return to the previous app; dismiss so home shows next steps.
        try? await Task.sleep(nanoseconds: 900_000_000)
        onFinished()
    }
}
