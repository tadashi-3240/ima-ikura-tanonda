import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("入力は登録タブのテキスト欄で行います。音声を使う場合は、キーボードのマイク（音声入力）を選んでください。アプリ独自の巨大マイク画面はありません。")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("入力について")
                        .font(.system(size: 16, weight: .semibold))
                }

                Section {
                    Text("場所に近づいたときの通知・距離設定・専用音は第3段階で追加します。いまの予定登録では端末内への保存までです。")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("位置通知（未実装）")
                        .font(.system(size: 16, weight: .semibold))
                }

                Section {
                    Text("履歴の保存とワンタップ再登録は第4段階です。")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("履歴（未実装）")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
