import SwiftUI

struct ContentView: View {
    var onStartVoice: (() -> Void)?
    @StateObject private var dictionaryViewModel = DictionaryViewModel()

    var body: some View {
        TabView {
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
