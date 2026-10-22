import SwiftUI

/// 切り分け用の超単純な確認画面。MapKit / 位置 / PlaceSearch は使わない。
struct SimpleUtteranceConfirmView: View {
    let rawText: String
    var onBack: () -> Void

    @State private var placeText: String
    @State private var taskText: String

    init(rawText: String, onBack: @escaping () -> Void) {
        self.rawText = rawText
        self.onBack = onBack
        let parsed = UtteranceParser.parse(rawText)
        _placeText = State(initialValue: parsed.placePhrase)
        _taskText = State(initialValue: parsed.taskPhrase)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("build: next-simple-1")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("内容の確認")
                    .font(.system(size: 28, weight: .bold))

                Text("入力した文章")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(rawText)
                    .font(.system(size: 22, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("場所")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("例：金古のセブンイレブン", text: $placeText)
                        .font(.system(size: 22))
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("用事")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("例：牛乳を買う", text: $taskText)
                        .font(.system(size: 22))
                        .textFieldStyle(.roundedBorder)
                }

                Text("場所検索・地図はこのあとつなぎます。まずはこの画面が見えればOKです。")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Button(action: onBack) {
                    Text("戻る")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
        }
    }
}

#Preview {
    SimpleUtteranceConfirmView(rawText: "金古のセブンイレブンで牛乳を買う") {}
}
