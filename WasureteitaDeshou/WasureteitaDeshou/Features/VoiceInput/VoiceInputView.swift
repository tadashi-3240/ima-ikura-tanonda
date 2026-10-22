import SwiftUI

struct VoiceInputView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var showPermissionExplainer = false
    @State private var didHandleLaunchAutoStart = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer(minLength: 12)

                Text(statusTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                transcriptBlock

                Spacer(minLength: 8)

                micButton

                if recognizer.isListening {
                    Text("もう一度タップで停止")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = recognizer.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if !recognizer.transcript.isEmpty && !recognizer.isListening {
                    Button("クリア") {
                        recognizer.clearTranscript()
                    }
                    .font(.system(size: 18, weight: .medium))
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .navigationTitle("忘れていたでしょう")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPermissionExplainer) {
                PermissionExplainerView(
                    onAllow: {
                        showPermissionExplainer = false
                        Task {
                            let granted = await recognizer.requestPermissions()
                            if granted {
                                recognizer.startListening()
                            }
                        }
                    },
                    onLater: {
                        showPermissionExplainer = false
                    }
                )
            }
            .onAppear {
                recognizer.refreshPermissionState()
                handleLaunchAutoStartIfNeeded()
            }
        }
    }

    private var statusTitle: String {
        if recognizer.isListening {
            return "聞いています…"
        }
        switch recognizer.permissionState {
        case .denied, .restricted:
            return "設定アプリでマイクと音声認識を許可してください"
        default:
            return "タップして話す"
        }
    }

    private var transcriptBlock: some View {
        Group {
            if recognizer.transcript.isEmpty {
                Text("ここに認識した文字が表示されます")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    Text(recognizer.transcript)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .frame(maxHeight: 220)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(recognizer.transcript.isEmpty ? "認識結果なし" : recognizer.transcript)
    }

    private var micButton: some View {
        Button(action: handleMicTap) {
            ZStack {
                Circle()
                    .fill(recognizer.isListening ? Color.red.opacity(0.18) : Color("BrandAccent").opacity(0.15))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(recognizer.isListening ? Color.red : Color("BrandAccent"))
                    .frame(width: 132, height: 132)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 6)

                Image(systemName: recognizer.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recognizer.isListening ? "音声入力を停止" : "音声入力を開始")
    }

    private func handleMicTap() {
        recognizer.refreshPermissionState()
        if recognizer.isListening {
            recognizer.stopListening()
            return
        }

        switch recognizer.permissionState {
        case .granted:
            recognizer.startListening()
        case .denied, .restricted:
            recognizer.errorMessage = "設定アプリでマイクと音声認識を許可してください。"
        case .needsRequest, .unknown:
            showPermissionExplainer = true
        }
    }

    private func handleLaunchAutoStartIfNeeded() {
        guard !didHandleLaunchAutoStart else { return }
        didHandleLaunchAutoStart = true
        guard settings.autoStartVoiceOnLaunch else { return }

        recognizer.refreshPermissionState()
        switch recognizer.permissionState {
        case .granted:
            recognizer.startListening()
        case .needsRequest, .unknown:
            showPermissionExplainer = true
        case .denied, .restricted:
            break
        }
    }
}

#Preview {
    VoiceInputView()
        .environmentObject(AppSettingsStore())
}
