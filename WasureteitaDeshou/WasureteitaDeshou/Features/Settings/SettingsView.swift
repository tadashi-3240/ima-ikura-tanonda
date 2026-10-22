import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notifySettings: AppNotifySettings
    @EnvironmentObject private var locationMonitor: LocationMonitor
    @EnvironmentObject private var reminderStore: ReminderStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("build: stage2-candidates-1")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

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
                    Picker("通知する距離", selection: $notifySettings.defaultNotifyDistanceMeters) {
                        Text("300 m").tag(300)
                        Text("500 m").tag(500)
                        Text("1000 m").tag(1000)
                    }
                    .font(.system(size: 18))

                    Text("新しく登録する予定の初期値です。各予定の編集画面でも変更できます。GPS や電波の都合で、実際に通知される距離は前後することがあり、正確な距離は保証しません。")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("位置通知")
                        .font(.system(size: 16, weight: .semibold))
                }

                Section {
                    LabeledContent("位置情報") {
                        Text(locationStatusLabel)
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    Button("位置情報の許可を求める") {
                        locationMonitor.requestWhenInUse()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            locationMonitor.requestAlways()
                        }
                    }
                    .font(.system(size: 17))

                    Button("通知の許可を求める") {
                        Task {
                            _ = await ReminderNotifier().requestAuthorization()
                        }
                    }
                    .font(.system(size: 17))

                    Button("監視を再同期") {
                        reminderStore.resyncMonitoring()
                    }
                    .font(.system(size: 17))

                    if let err = locationMonitor.lastErrorMessage {
                        Text(err)
                            .font(.system(size: 15))
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("権限")
                        .font(.system(size: 16, weight: .semibold))
                } footer: {
                    Text("バックグラウンドでも知らせるには、位置情報を「常に」にしてください。システム設定から変更することもできます。")
                        .font(.system(size: 14))
                }

                Section {
                    Text("履歴の保存とワンタップ再登録は第4段階です。音声での読み上げは第5段階で検証します（いまは通知音＋文字が基本です）。")
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
            .onAppear {
                locationMonitor.refreshAuthorizationStatus()
            }
        }
    }

    private var locationStatusLabel: String {
        switch locationMonitor.authorizationStatus {
        case .authorizedAlways: return "常に許可"
        case .authorizedWhenInUse: return "利用中のみ"
        case .denied: return "拒否"
        case .restricted: return "制限あり"
        case .notDetermined: return "未設定"
        @unknown default: return "不明"
        }
    }
}

#Preview {
    let monitor = LocationMonitor()
    return SettingsView()
        .environmentObject(AppNotifySettings())
        .environmentObject(monitor)
        .environmentObject(ReminderStore(locationMonitor: monitor))
}
