import SwiftUI

private struct VoiceSessionRoute: Identifiable {
    let id: UUID
}

@main
struct KyohoranguageHostApp: App {
    @State private var voiceRoute: VoiceSessionRoute?
    @State private var lastResultHint: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(
                onStartVoice: startVoiceFromHost,
                lastResultHint: lastResultHint
            )
            .fullScreenCover(item: $voiceRoute) { route in
                VoiceInputView(sessionId: route.id) {
                    let payload = VoiceBridge.load()
                    if payload.status == .ready {
                        let shown = payload.correctedText.isEmpty ? payload.rawText : payload.correctedText
                        lastResultHint = "直前の結果: \(shown)\nメモに戻るとキーボードが文字を入れます。"
                    }
                    voiceRoute = nil
                }
            }
            .onOpenURL { url in
                handleOpenURL(url)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    adoptPendingKeyboardRequestIfNeeded()
                }
            }
        }
    }

    private func startVoiceFromHost() {
        lastResultHint = nil
        let payload = VoiceBridge.beginRequest()
        voiceRoute = VoiceSessionRoute(id: payload.sessionId)
    }

    private func handleOpenURL(_ url: URL) {
        guard url.scheme == AppGroupConstants.urlScheme else { return }
        guard url.absoluteString.lowercased().contains("voice") else { return }

        let existing = VoiceBridge.load()
        let sessionId: UUID
        if existing.status == .requesting || existing.status == .listening {
            sessionId = existing.sessionId
        } else {
            sessionId = VoiceBridge.beginRequest().sessionId
        }
        voiceRoute = VoiceSessionRoute(id: sessionId)
    }

    private func adoptPendingKeyboardRequestIfNeeded() {
        guard voiceRoute == nil else { return }
        let payload = VoiceBridge.load()
        guard payload.status == .requesting, !VoiceBridge.isTimedOut(payload) else { return }
        voiceRoute = VoiceSessionRoute(id: payload.sessionId)
    }
}
