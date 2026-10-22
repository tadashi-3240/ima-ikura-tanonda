import SwiftUI

@main
struct WasureteitaDeshouApp: App {
    @StateObject private var draftStore: DraftUtteranceStore
    @StateObject private var notifySettings: AppNotifySettings
    @StateObject private var locationMonitor: LocationMonitor
    @StateObject private var reminderStore: ReminderStore

    init() {
        let draft = DraftUtteranceStore()
        let settings = AppNotifySettings()
        let monitor = LocationMonitor()
        let reminders = ReminderStore(locationMonitor: monitor)
        _draftStore = StateObject(wrappedValue: draft)
        _notifySettings = StateObject(wrappedValue: settings)
        _locationMonitor = StateObject(wrappedValue: monitor)
        _reminderStore = StateObject(wrappedValue: reminders)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(draftStore)
                .environmentObject(notifySettings)
                .environmentObject(locationMonitor)
                .environmentObject(reminderStore)
                .onAppear {
                    locationMonitor.refreshAuthorizationStatus()
                    reminderStore.resyncMonitoring()
                }
        }
    }
}
