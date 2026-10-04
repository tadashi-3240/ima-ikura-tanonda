import SwiftUI

struct ContentView: View {
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
                SetupGuideView()
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
