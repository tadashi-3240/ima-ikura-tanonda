import SwiftUI

private struct VoiceSessionRoute: Identifiable {
    let id: UUID
}

@main
struct KyohoranguageHostApp: App {
    @State private var voiceRoute: VoiceSessionRoute?

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
        if existing.status == .requesting {
            sessionId = existing.sessionId
        } else {
            sessionId = VoiceBridge.beginRequest().sessionId
        }
        voiceRoute = VoiceSessionRoute(id: sessionId)
    }
}
