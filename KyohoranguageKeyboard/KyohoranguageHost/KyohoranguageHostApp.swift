import SwiftUI

private struct VoiceSessionRoute: Identifiable, Equatable {
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
                NavigationStack {
                    VoiceInputView(sessionId: route.id) {
                        updateHintAfterVoice()
                        voiceRoute = nil
                    }
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
        // Dismiss any stale cover first, then present a fresh session.
        if voiceRoute != nil {
            voiceRoute = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                presentNewVoiceSession()
            }
        } else {
            presentNewVoiceSession()
        }
    }

    private func presentNewVoiceSession() {
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

    private func updateHintAfterVoice() {
        if let last = VoiceBridge.loadLastResult() {
            let shown = last.correctedText.isEmpty ? last.rawText : last.correctedText
            lastResultHint = "コピーしました。メモで長押し→ペースト\n「\(shown)」"
            return
        }
        let payload = VoiceBridge.load()
        if payload.status == .ready {
            let shown = payload.correctedText.isEmpty ? payload.rawText : payload.correctedText
            lastResultHint = "コピーしました。メモで長押し→ペースト\n「\(shown)」"
        }
    }
}
