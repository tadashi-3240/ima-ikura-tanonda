import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notifySettings: AppNotifySettings
    @EnvironmentObject private var locationMonitor: LocationMonitor
    @EnvironmentObject private var reminderStore: ReminderStore

    @State private var testNotifyMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("build: stage3-geo-2")
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(locationStatusColor)
                    }

                    LabeledContent("監視中の場所") {
                        Text("\(locationMonitor.monitoredRegionCount) 件")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }

                    if locationMonitor.authorizationStatus != .authorizedAlways {
                        Text("バックグラウンドで近づいたことを確実に知らせるには、位置情報を「常に」にしてください。「利用中のみ」だとアプリを閉じているときの進入検知が弱くなります。")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.orange)
                            .padding(.vertical, 4)
                    }

                    Button("位置情報を「常に」にする") {
                        locationMonitor.requestWhenInUse()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            locationMonitor.requestAlways()
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))

                    Button("通知の許可を求める") {
                        Task {
                            _ = await ReminderNotifier().requestAuthorization()
                        }
                    }
                    .font(.system(size: 17))

                    Button("テスト通知を送る") {
                        ReminderNotifier().postTestNotification { success, errorMessage in
                            if success {
                                testNotifyMessage = "テスト通知を送りました。"
                            } else {
                                testNotifyMessage = errorMessage ?? "テスト通知に失敗しました。"
                            }
                        }
                    }
                    .font(.system(size: 17))

                    Button("圏内を再判定") {
                        reminderStore.resyncMonitoring()
                        locationMonitor.requestStateForAllMonitoredRegions()
                        testNotifyMessage = "監視を再同期し、圏内かどうかを問い合わせました。"
                    }
                    .font(.system(size: 17))

                    if let msg = testNotifyMessage {
                        Text(msg)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    if let err = locationMonitor.lastErrorMessage {
                        Text(err)
                            .font(.system(size: 15))
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("権限・動作確認")
                        .font(.system(size: 16, weight: .semibold))
                } footer: {
                    Text("バックグラウンドでも知らせるには、設定アプリでこのアプリの位置情報を「常に」にしてください。iOS の領域監視（ジオフェンス）は、進入・退出の検知に数分かかることがあります。すぐ反応しない場合は「圏内を再判定」を試すか、しばらく待ってください。")
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
        case .authorizedWhenInUse: return "利用中のみ（常に推奨）"
        case .denied: return "拒否"
        case .restricted: return "制限あり"
        case .notDetermined: return "未設定"
        @unknown default: return "不明"
        }
    }

    private var locationStatusColor: Color {
        switch locationMonitor.authorizationStatus {
        case .authorizedAlways: return .secondary
        case .authorizedWhenInUse: return .orange
        case .denied, .restricted: return .red
        default: return .secondary
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
