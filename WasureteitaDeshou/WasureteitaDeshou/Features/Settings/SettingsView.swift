import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $settings.autoStartVoiceOnLaunch) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("起動時に自動開始")
                                .font(.system(size: 20, weight: .semibold))
                            Text("アプリを開いたとき、音声入力をすぐに始めます。初回は許可の説明が表示されます。")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .tint(Color("BrandAccent"))
                } header: {
                    Text("音声入力")
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
        .environmentObject(AppSettingsStore())
}
