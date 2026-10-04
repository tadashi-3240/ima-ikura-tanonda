import SwiftUI
import UIKit

/// Full-screen voice UI — Notes path is copy then long-press paste.
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
    @State private var copyFailed = false

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

            if finishedText != nil {
                pasteSuccessPanel
            } else {
                listeningPanel
            }

            Spacer(minLength: 8)

            if finishedText != nil {
                Button {
                    if let finishedText {
                        _ = ClipboardCopy.copyPlainText(finishedText)
                        VoiceBridge.saveClipboardText(finishedText)
                    }
                    onFinished()
                } label: {
                    Text("メモに戻って長押し→ペースト")
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 84)
                }
                .buttonStyle(.borderedProminent)

                Button("もう一度コピー") {
                    guard let finishedText else { return }
                    copyFailed = !ClipboardCopy.copyPlainText(finishedText)
                    VoiceBridge.saveClipboardText(finishedText)
                }
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
            } else {
                Button {
                    Task { await completeAndCopy() }
                } label: {
                    Text(isCompleting ? "処理中…" : "完了してコピー")
                        .font(.system(size: 30, weight: .bold))
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

    private var listeningPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusBanner

            Text("いまの言葉")
                .font(.title2.weight(.semibold))
            Text(speech.displayText.isEmpty ? "（まだ聞こえていません）" : speech.displayText)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(speech.displayText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if correctionEnabled, !speech.displayText.isEmpty {
                Text("辞書補正後（これをコピーします）")
                    .font(.title3.weight(.semibold))
                Text(correctedPreview)
                    .font(.system(size: 26, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.green.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var pasteSuccessPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("コピーしました。メモで長押し→ペースト")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)

            if let finishedText {
                Text(finishedText)
                    .font(.system(size: 30, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.green.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("これだけやってください")
                    .font(.title2.weight(.bold))
                Text("1. 下の青いボタンを押す")
                Text("2. メモを開く")
                Text("3. 入力欄を長押し → ペースト")
            }
            .font(.title3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if copyFailed {
                Text("コピーに失敗したかもしれません。「もう一度コピー」を押してください。")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            if let finishedMessage {
                Text(finishedMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func autoStartIfNeeded() async {
        guard !didAutoStart else { return }
        didAutoStart = true
        _ = store.seedInitialEntriesIfEmpty()
        try? await Task.sleep(nanoseconds: 200_000_000)
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
            Text("準備中…")
                .font(.title3)
        }
    }

    private func completeAndCopy() async {
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
            await speech.retryListening()
            return
        }

        let engine = store.makeEngine()
        let corrected = engine.correct(raw, enabled: store.isCorrectionEnabled())
        let forPaste = store.isCorrectionEnabled() ? corrected : raw

        VoiceBridge.markReady(sessionId: sessionId, rawText: raw, correctedText: corrected)

        var ok = ClipboardCopy.copyPlainText(forPaste)
        VoiceBridge.saveClipboardText(forPaste)
        try? await Task.sleep(nanoseconds: 150_000_000)
        if ClipboardCopy.copyPlainText(forPaste) {
            ok = true
        }
        VoiceBridge.saveClipboardText(forPaste)

        finishedText = forPaste
        copyFailed = !ok
        errorMessage = nil
        finishedMessage = ok
            ? "クリップボードに保存済みです。"
            : "コピー確認に失敗しました。もう一度コピーを押してください。"
    }
}
