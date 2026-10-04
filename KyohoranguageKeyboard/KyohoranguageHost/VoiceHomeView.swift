import SwiftUI

/// Primary voice entry — host-first reliable path for non-technical users.
struct VoiceHomeView: View {
    var onStartVoice: () -> Void
    var lastResultHint: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("協豊ランゲージ")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("いちばん確実な音声入力")
                    .font(.title.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("下の大きなボタンを押して話します。終わったら「完了」→ メモに戻ってください。")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onStartVoice) {
                    VStack(spacing: 14) {
                        Text("🎤")
                            .font(.system(size: 72))
                        Text("音声入力")
                            .font(.system(size: 40, weight: .bold))
                        Text("ここを押して話す")
                            .font(.title2.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(Color.red.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .buttonStyle(.plain)

                if let lastResultHint, !lastResultHint.isEmpty {
                    Text(lastResultHint)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("かんたん5ステップ")
                        .font(.title2.weight(.bold))
                    Text("① このボタンを押す")
                    Text("② 「話してください」と出たら話す")
                    Text("③ 「完了」を押す（補正後を確認）")
                    Text("④ 「メモに戻る」→ メモ／LINE を開く")
                    Text("⑤ 協豊キーボードを出す（入らなければ「結果を貼る」）")
                }
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("キーボードの🎤が動かないときは、必ずこの画面から入力してください。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("音声")
        .navigationBarTitleDisplayMode(.inline)
    }
}
