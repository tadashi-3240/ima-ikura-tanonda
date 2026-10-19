import SwiftUI

struct ContentView: View {
    var onStartVoice: (() -> Void)?
    var lastResultHint: String? = nil
    @StateObject private var dictionaryViewModel = DictionaryViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                VoiceHomeView(onStartVoice: { onStartVoice?() }, lastResultHint: lastResultHint)
            }
            .tabItem {
                Label("音声", systemImage: "mic.fill")
            }

            NavigationStack {
                DictionaryListView(viewModel: dictionaryViewModel)
            }
            .tabItem {
                Label("辞書", systemImage: "book")
            }

            NavigationStack {
                SetupGuideView(onStartVoice: onStartVoice)
            }
            .tabItem {
                Label("セットアップ", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    ContentView()
}
