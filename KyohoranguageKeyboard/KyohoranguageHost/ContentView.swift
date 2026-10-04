import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("協豊ランゲージ")
                        .font(.largeTitle.bold())

                    Text("カスタムキーボードを追加して、地球儀から切り替えてください。")
                        .foregroundStyle(.secondary)

                    Group {
                        Label("設定 → 一般 → キーボード → キーボード", systemImage: "1.circle.fill")
                        Label("「新しいキーボードを追加…」→ 協豊ランゲージ", systemImage: "2.circle.fill")
                        Label("協豊ランゲージ → フルアクセスを許可（辞書共有に必要）", systemImage: "3.circle.fill")
                        Label("メモなどで地球儀から「協豊ランゲージ」を選択", systemImage: "4.circle.fill")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    Text("マイルストーン1")
                        .font(.headline)
                    Text("キーボードが一覧と切替に表示されることまでが目標です。変換・辞書編集・音声は次のフェーズです。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("App Group: \(AppGroupConstants.suiteName)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .navigationTitle("セットアップ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
