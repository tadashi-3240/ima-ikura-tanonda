import SwiftUI

/// Full-screen voice UI (from keyboard deep link or host home button).
struct VoiceInputView: View {
    let sessionId: UUID
    var onFinished: () -> Void

    @StateObject private var speech = SpeechRecognitionController()
    private let store = DictionaryStore()
    @State private var didAutoStart = false
    @State private var finishedMessage: String?

    private var correctionEnabled: Bool {
        store.isCorrectionEnabled()
    }

    private var correctedPreview: String {
        let engine = store.makeEngine()
        return engine.correct(speech.displayText, enabled: correctionEnabled)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("協豊ランゲージ 音声入力")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            statusBanner

            VStack(alignment: .leading, spacing: 8) {
                Text("認識中")
                    .font(.headline)
                Text(speech.displayText.isEmpty ? "…" : speech.displayText)
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if correctionEnabled, !speech.displayText.isEmpty {
                    Text("補正後プレビュー")
                        .font(.headline)
                    Text(correctedPreview.isEmpty ? "…" : correctedPreview)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else if !correctionEnabled {
                    Text("辞書補正は OFF です（認識どおり挿入されます）")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let finishedMessage {
                Text(finishedMessage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                complete()
            } label: {
                Text("完了")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 72)
            }
            .buttonStyle(.borderedProminent)
            .disabled(speech.phase == .requestingPermission)

            Button("やめる") {
                speech.cancel()
                onFinished()
            }
            .font(.title3)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .padding(24)
        .task {
            await autoStartIfNeeded()
        }
        .onAppear {
            Task { await autoStartIfNeeded() }
        }
    }

    private func autoStartIfNeeded() async {
        guard !didAutoStart else { return }
        didAutoStart = true
        // Ensure seed dictionary exists for preview correction.
        _ = store.seedInitialEntriesIfEmpty()
        await speech.prepareAndStart(sessionId: sessionId)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch speech.phase {
        case .listening:
            Label("話してください", systemImage: "mic.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.red)
        case .requestingPermission:
            Label("マイクと音声認識の許可を確認しています…", systemImage: "ellipsis.circle")
                .font(.title3)
        case .finishing:
            Label("処理中…", systemImage: "hourglass")
                .font(.title3)
        case .unavailable(let message):
            Text(message)
                .font(.title3)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.leading)
        case .idle:
            if finishedMessage == nil {
                Label("準備中…", systemImage: "mic")
                    .font(.title3)
            }
        }
    }

    private func complete() {
        let raw = speech.finish()
        guard !raw.isEmpty else {
            VoiceBridge.markError(sessionId: sessionId, message: "empty transcript")
            finishedMessage = "声を認識できませんでした。もう一度試してください。"
            return
        }

        VoiceBridge.markReady(sessionId: sessionId, rawText: raw)
        finishedMessage = "完了しました。\n前のアプリ（メモ / LINE など）に戻ると、文字が入ります。"
    }
}
