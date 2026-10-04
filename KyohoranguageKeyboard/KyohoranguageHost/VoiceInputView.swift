import SwiftUI
import UIKit

/// Read-only selectable text so long-press shows the system Copy menu.
struct SelectableTextBox: UIViewRepresentable {
    let text: String
    var font: UIFont = .systemFont(ofSize: 26, weight: .semibold)
    var minHeight: CGFloat = 90

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        view.font = font
        view.textColor = .label
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
    }
}

/// Full-screen voice UI — Notes path requires explicit Copy button + selectable text.
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
    @State private var showCopyAlert = false
    @State private var copyBanner: String?

    private var correctionEnabled: Bool {
        store.isCorrectionEnabled()
    }

    /// Text that should be copied (corrected when ON).
    private var textToCopy: String {
        if let finishedText, !finishedText.isEmpty {
            return finishedText
        }
        let raw = speech.displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "" }
        return store.makeEngine().correct(raw, enabled: correctionEnabled)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("音声入力")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let copyBanner {
                Text(copyBanner)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if finishedText != nil {
                pasteSuccessPanel
            } else {
                listeningPanel
            }

            Spacer(minLength: 4)

            // LARGE primary Copy — always available when there is text.
            Button {
                performCopy(textToCopy)
            } label: {
                Text("コピー")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 78)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(textToCopy.isEmpty || isCompleting)

            if finishedText == nil {
                Button {
                    Task { await completeRecognition() }
                } label: {
                    Text(isCompleting ? "処理中…" : "完了")
                        .font(.system(size: 28, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 64)
                }
                .buttonStyle(.bordered)
                .disabled(isCompleting || speech.phase == .requestingPermission)

                if case .unavailable = speech.phase {
                    Button("もう一度話す") {
                        errorMessage = nil
                        finishedMessage = nil
                        finishedText = nil
                        copyBanner = nil
                        Task { await speech.retryListening() }
                    }
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                }

                Button("やめる") {
                    speech.cancel()
                    onFinished()
                }
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                Button(action: onFinished) {
                    Text("閉じる（メモに戻る）")
                        .font(.system(size: 24, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 64)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .task { await autoStartIfNeeded() }
        .onAppear { Task { await autoStartIfNeeded() } }
        .alert("コピーしました。メモで長押し→ペースト", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(textToCopy.isEmpty ? "補正後の文字をコピーしました。" : "「\(textToCopy)」")
        }
    }

    private var listeningPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusBanner

            Text("いまの言葉")
                .font(.title2.weight(.semibold))
            Text(speech.displayText.isEmpty ? "（まだ聞こえていません）" : speech.displayText)
                .font(.system(size: 26, weight: .medium))
                .textSelection(.enabled)
                .foregroundStyle(speech.displayText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(correctionEnabled ? "辞書補正後（長押しでもコピー可）" : "認識結果（長押しでもコピー可）")
                .font(.title3.weight(.semibold))

            SelectableTextBox(
                text: textToCopy.isEmpty ? "（ここに補正後の文字が出ます）" : textToCopy,
                font: .systemFont(ofSize: 26, weight: .semibold),
                minHeight: 100
            )
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(4)
            .background(Color.green.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if let errorMessage {
                Text(errorMessage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var pasteSuccessPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("コピーしました。メモで長押し→ペースト")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)

            Text("下の文字を長押ししてもコピーできます")
                .font(.title3)

            SelectableTextBox(
                text: finishedText ?? "",
                font: .systemFont(ofSize: 30, weight: .semibold),
                minHeight: 110
            )
            .frame(maxWidth: .infinity, minHeight: 110)
            .padding(4)
            .background(Color.green.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 10) {
                Text("次の手順")
                    .font(.title2.weight(.bold))
                Text("1. 緑の「コピー」をもう一度押してもよい")
                Text("2. メモを開く")
                Text("3. 入力欄を長押し → ペースト")
            }
            .font(.title3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if copyFailed {
                Text("コピーに失敗したかもしれません。緑の「コピー」を押してください。")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
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
                .font(.system(size: 30, weight: .bold))
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

    private func performCopy(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            copyFailed = true
            errorMessage = "コピーする文字がありません。話してから押してください。"
            return
        }

        var ok = ClipboardCopy.copyPlainText(trimmed)
        VoiceBridge.saveClipboardText(trimmed)
        // Second write improves reliability on some devices.
        if ClipboardCopy.copyPlainText(trimmed) {
            ok = true
        }

        copyFailed = !ok
        if ok {
            copyBanner = "コピーしました。メモで長押し→ペースト"
            finishedMessage = copyBanner
            showCopyAlert = true
            // If recognition already finished, keep success panel text.
            if finishedText == nil, speech.phase == .idle || speech.phase == .listening {
                // Keep listening text available; don't force finish panel yet.
            }
            if let finishedText, finishedText != trimmed {
                self.finishedText = trimmed
            }
        } else {
            copyBanner = nil
            errorMessage = "コピーできませんでした。もう一度「コピー」を押してください。"
        }
    }

    private func completeRecognition() async {
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
        finishedText = forPaste
        errorMessage = nil

        // Always copy on 完了 as well, then keep instructions on screen.
        performCopy(forPaste)
    }
}
