import SwiftUI

@main
struct WasureteitaDeshouApp: App {
    @StateObject private var draftStore = DraftUtteranceStore()
    @StateObject private var reminderStore = ReminderStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(draftStore)
                .environmentObject(reminderStore)
        }
    }
}
