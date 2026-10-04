import SwiftUI
import UIKit

/// Primary voice entry — host-first reliable path for non-technical users.
struct VoiceHomeView: View {
    var onStartVoice: () -> Void
    var lastResultHint: String?
    @State private var isLaunching = false
    @State private var tapFlash = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("協豊ランゲージ")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("メモに文字を入れるいちばん確実な方法")
                    .font(.title.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("キーボードの🎤ではメモが開けないことがあります。ここで話して「完了してコピー」→ メモで長押しペーストしてください。")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    guard !isLaunching else { return }
                    isLaunching = true
                    tapFlash = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onStartVoice()
                    // Allow re-tap if cover failed to present.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        isLaunching = false
                        tapFlash = false
                    }
                } label: {
                    VStack(spacing: 14) {
                        Text("🎤")
                            .font(.system(size: 72))
                        Text(isLaunching ? "起動中…" : "音声入力")
                            .font(.system(size: 40, weight: .bold))
                        Text(isLaunching ? "画面が開きます" : "ここを押して話す")
                            .font(.title2.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .background(
                        (tapFlash ? Color.orange : Color.red).gradient
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .contentShape(RoundedRectangle(cornerRadius: 28))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.55), lineWidth: 3)
                    }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("音声入力")
                .accessibilityHint("押すと音声入力画面が開きます")

                if isLaunching {
                    Text("音声画面を開いています…")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let lastResultHint, !lastResultHint.isEmpty {
                    Text(lastResultHint)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("かんたん5ステップ")
                        .font(.title2.weight(.bold))
                    Text("① この赤いボタンを押す")
                    Text("② 話して「完了してコピー」")
                    Text("③ 「コピーしました。メモで長押し→ペースト」を確認")
                    Text("④ メモを開く")
                    Text("⑤ 入力欄を長押し → ペースト")
                }
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("キーボードの🎤が動かないときは、必ずこの画面の赤いボタンから入力してください。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("音声")
        .navigationBarTitleDisplayMode(.inline)
    }
}
