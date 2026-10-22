import SwiftUI

/// 初回のマイク＋音声認識許可の前に、用途を日本語で説明する。
struct PermissionExplainerView: View {
    let onAllow: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("音声入力の許可")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            Text("「忘れていたでしょう」は、話した内容を文字にするためにマイクと音声認識を使います。録音は端末内の認識に使われ、場所の検索や通知はこの段階では行いません。")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Label("マイク：声を聞き取る", systemImage: "mic.fill")
                Label("音声認識：文字に変換する", systemImage: "text.bubble.fill")
            }
            .font(.system(size: 18, weight: .medium))

            Spacer(minLength: 8)

            Button(action: onAllow) {
                Text("許可する")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)

            Button("あとで", action: onLater)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
