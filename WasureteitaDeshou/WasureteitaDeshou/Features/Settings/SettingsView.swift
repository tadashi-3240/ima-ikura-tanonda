import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("入力は登録タブのテキスト欄で行います。音声を使う場合は、キーボードのマイク（音声入力）を選んでください。アプリ独自の音声認識や起動時の自動開始はありません。")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("入力について")
                        .font(.system(size: 16, weight: .semibold))
                }

                Section {
                    Text("場所の検索・地図・位置通知・履歴の本機能は、これから段階的に追加します。")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("今後の予定")
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
