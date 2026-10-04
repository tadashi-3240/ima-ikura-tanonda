import SwiftUI

/// Home screen entry: large voice button for manual flow when keyboard cannot open the host.
struct VoiceHomeView: View {
    var onStartVoice: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("協豊ランゲージ")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("キーボードから開けないときは、ここから音声入力できます。")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onStartVoice) {
                    VStack(spacing: 12) {
                        Text("🎤")
                            .font(.system(size: 56))
                        Text("音声入力")
                            .font(.system(size: 32, weight: .bold))
                        Text("タップして話す")
                            .font(.title3)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color.red.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("使い方")
                        .font(.headline)
                    Text("1. このボタン（またはキーボードの🎤）で開始")
                    Text("2. 「話してください」と出たら話す")
                    Text("3. 「完了」を押す")
                    Text("4. メモ / LINE など、入力していたアプリに戻る")
                    Text("5. 協豊キーボードが表示されていれば、文字が入ります")
                }
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("※ キーボードから直接開くには「フルアクセスを許可」が必要です。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("音声")
        .navigationBarTitleDisplayMode(.inline)
    }
}
