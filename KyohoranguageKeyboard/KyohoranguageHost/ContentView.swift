import SwiftUI

struct ContentView: View {
    var onStartVoice: (() -> Void)?
    @StateObject private var dictionaryViewModel = DictionaryViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                VoiceHomeView {
                    onStartVoice?()
                }
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
