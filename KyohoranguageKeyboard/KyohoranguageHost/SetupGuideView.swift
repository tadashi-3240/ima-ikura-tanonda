import SwiftUI

struct SetupGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("協豊ランゲージ")
                    .font(.largeTitle.bold())

                Text("カスタムキーボードを追加し、辞書補正を試してください。")
                    .foregroundStyle(.secondary)

                Group {
                    Label("設定 → 一般 → キーボード → キーボード", systemImage: "1.circle.fill")
                    Label("「新しいキーボードを追加…」→ 協豊ランゲージ", systemImage: "2.circle.fill")
                    Label("協豊ランゲージ → フルアクセスを許可（必須）", systemImage: "3.circle.fill")
                    Label("メモ等で地球儀から「協豊ランゲージ」を選択", systemImage: "4.circle.fill")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                Text("マイルストーン2 の確認")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. キーボードの「候補」タブで「金子」を入力エリアに入れる")
                    Text("2. 「辞書補正 ON」のまま「確定」を押す")
                    Text("3. メモ欄に「金古」が入ること")
                    Text("4. 「金子町」→「金古町」（長い一致が優先）")
                    Text("5. ホスト辞書で誤認識を追加し、キーボード再表示後に反映されること")
                }
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
