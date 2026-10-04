import SwiftUI

private struct VoiceSessionRoute: Identifiable {
    let id: UUID
}

@main
struct KyohoranguageHostApp: App {
    @State private var voiceRoute: VoiceSessionRoute?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(onStartVoice: startVoiceFromHost)
                .fullScreenCover(item: $voiceRoute) { route in
                    VoiceInputView(sessionId: route.id) {
                        voiceRoute = nil
                    }
                }
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .onChange(of: scenePhase) { newPhase in
                    // If launched cold via URL before SwiftUI attached, retry pending request.
                    if newPhase == .active {
                        adoptPendingKeyboardRequestIfNeeded()
                    }
                }
        }
    }

    private func startVoiceFromHost() {
        let payload = VoiceBridge.beginRequest()
        voiceRoute = VoiceSessionRoute(id: payload.sessionId)
    }

    private func handleOpenURL(_ url: URL) {
        guard url.scheme == AppGroupConstants.urlScheme else { return }
        let absolute = url.absoluteString.lowercased()
        guard absolute.contains("voice") else { return }

        let existing = VoiceBridge.load()
        let sessionId: UUID
        if existing.status == .requesting || existing.status == .listening {
            sessionId = existing.sessionId
        } else {
            sessionId = VoiceBridge.beginRequest().sessionId
        }
        voiceRoute = VoiceSessionRoute(id: sessionId)
    }

    /// When user opens the host manually after tapping mic, pick up the keyboard's requesting session.
    private func adoptPendingKeyboardRequestIfNeeded() {
        guard voiceRoute == nil else { return }
        let payload = VoiceBridge.load()
        guard payload.status == .requesting, !VoiceBridge.isTimedOut(payload) else { return }
        voiceRoute = VoiceSessionRoute(id: payload.sessionId)
    }
}
