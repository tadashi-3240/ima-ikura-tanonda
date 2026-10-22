import SwiftUI

@main
struct WasureteitaDeshouApp: App {
    @StateObject private var settings = AppSettingsStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
        }
    }
}
