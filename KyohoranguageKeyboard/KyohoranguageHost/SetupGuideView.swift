import SwiftUI

struct SetupGuideView: View {
    var onStartVoice: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("協豊ランゲージ")
                    .font(.largeTitle.bold())

                Text("キーボード追加・辞書補正・音声入力の案内です。")
                    .foregroundStyle(.secondary)

                Group {
                    Label("設定 → 一般 → キーボード → キーボード", systemImage: "1.circle.fill")
                    Label("「新しいキーボードを追加…」→ 協豊ランゲージ", systemImage: "2.circle.fill")
                    Label("協豊ランゲージ → フルアクセスを許可（必須）", systemImage: "3.circle.fill")
                    Label("メモ等で地球儀から「協豊ランゲージ」を選択", systemImage: "4.circle.fill")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                Text("辞書補正の確認")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text("候補「金子」→ 確定 → 金古")
                    Text("「金子町」→ 金古町（長い一致優先）")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text("音声入力の確認")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text("いちばん確実: アプリの「音声」タブの赤いボタン")
                    Text("1. 赤い「音声入力」をタップ（反応して起動中と出ます）")
                    Text("2. 「話してください」→ 話す")
                    Text("3. 「完了」→「メモに戻る」")
                    Text("4. メモで協豊キーボード → 自動挿入 or「結果を貼る」")
                    Text("キーボードの🎤が無反応なら、必ずアプリの赤いボタンを使ってください")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let onStartVoice {
                    Button {
                        onStartVoice()
                    } label: {
                        Text("音声入力を試す（ホストから）")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("URL: \(AppGroupConstants.voiceURL.absoluteString)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
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
