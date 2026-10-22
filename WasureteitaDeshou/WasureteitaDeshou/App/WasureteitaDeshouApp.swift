import SwiftUI

@main
struct WasureteitaDeshouApp: App {
    @StateObject private var draftStore = DraftUtteranceStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(draftStore)
        }
    }
}
