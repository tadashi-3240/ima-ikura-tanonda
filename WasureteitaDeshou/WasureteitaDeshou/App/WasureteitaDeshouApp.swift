import SwiftUI

@main
struct WasureteitaDeshouApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var draftStore: DraftUtteranceStore
    @StateObject private var notifySettings: AppNotifySettings
    @StateObject private var locationMonitor: LocationMonitor
    @StateObject private var reminderStore: ReminderStore
    @StateObject private var homeStore: HomePlaceStore

    init() {
        let draft = DraftUtteranceStore()
        let settings = AppNotifySettings()
        let monitor = LocationMonitor()
        let reminders = ReminderStore(locationMonitor: monitor)
        let home = HomePlaceStore()
        _draftStore = StateObject(wrappedValue: draft)
        _notifySettings = StateObject(wrappedValue: settings)
        _locationMonitor = StateObject(wrappedValue: monitor)
        _reminderStore = StateObject(wrappedValue: reminders)
        _homeStore = StateObject(wrappedValue: home)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(draftStore)
                .environmentObject(notifySettings)
                .environmentObject(locationMonitor)
                .environmentObject(reminderStore)
                .environmentObject(homeStore)
                .onAppear {
                    refreshLocationMonitoring()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        refreshLocationMonitoring()
                    }
                }
        }
    }

    private func refreshLocationMonitoring() {
        locationMonitor.refreshAuthorizationStatus()
        reminderStore.resyncMonitoring()
        locationMonitor.requestStateForAllMonitoredRegions()
    }
}
