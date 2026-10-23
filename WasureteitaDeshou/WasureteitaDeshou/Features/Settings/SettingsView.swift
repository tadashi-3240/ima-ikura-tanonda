import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var notifySettings: AppNotifySettings
    @EnvironmentObject private var locationMonitor: LocationMonitor
    @EnvironmentObject private var reminderStore: ReminderStore

    @State private var testNotifyMessage: String?
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("build: stage4-dwell-1")
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

                    LabeledContent("通知") {
                        Text(notificationStatusLabel)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(notificationStatusColor)
                    }

                    LabeledContent("監視中の領域") {
                        Text("\(locationMonitor.monitoredRegionCount) 件")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("滞在計測中") {
                        Text("\(locationMonitor.dwellTrackingCount) 件")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }

                    if locationMonitor.authorizationStatus != .authorizedAlways {
                        Text("バックグラウンドで近づいたことを確実に知らせるには、位置情報を「常に」にしてください。「利用中のみ」だとアプリを閉じているときの進入検知が弱くなります。")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.orange)
                            .padding(.vertical, 4)
                    }

                    if notificationAuthStatus == .denied {
                        Text("許可されていません。iPhone設定→通知→忘れていたでしょう、でオンにしてください。")
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
                            await refreshNotificationAuthStatus()
                            if notificationAuthStatus == .denied {
                                testNotifyMessage = "許可されていません。iPhone設定→通知→忘れていたでしょう、でオンにしてください。"
                            } else if notificationAuthStatus == .authorized || notificationAuthStatus == .provisional {
                                testNotifyMessage = "通知は許可されています。"
                            }
                        }
                    }
                    .font(.system(size: 17))

                    Button("テスト通知を送る") {
                        Task {
                            await sendTestNotification()
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
                    Text("バックグラウンドでも知らせるには、設定アプリでこのアプリの位置情報を「常に」にしてください。iOS の領域監視（ジオフェンス）は、進入・退出の検知に数分かかることがあります。すぐ反応しない場合は「圏内を再判定」を試すか、しばらく待ってください。アプリ前面でもテスト通知のバナーが出ます。")
                        .font(.system(size: 14))
                }

                Section {
                    Text("店舗付近（目安 50〜100m）に約1分滞在すると、予定を自動解除して履歴へ移し、同じ予定は再通知しません。領域の進入・退出と、滞在中だけの限定的な位置更新で判定します。バックグラウンドでは正確な1分を保証できません（アプリが起きていないと計測が遅れることがあります）。")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("自動解除（滞在）")
                        .font(.system(size: 16, weight: .semibold))
                }

                Section {
                    Text("音声での読み上げは第5段階で検証します（いまは通知音＋文字が基本です）。未実装を実装済みとはしません。")
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
                Task { await refreshNotificationAuthStatus() }
            }
        }
    }

    private func refreshNotificationAuthStatus() async {
        notificationAuthStatus = await ReminderNotifier().authorizationStatus()
    }

    private func sendTestNotification() async {
        let notifier = ReminderNotifier()
        var status = await notifier.authorizationStatus()

        if status == .notDetermined {
            _ = await notifier.requestAuthorization()
            status = await notifier.authorizationStatus()
        }

        notificationAuthStatus = status

        switch status {
        case .denied, .notDetermined:
            testNotifyMessage = "許可されていません。iPhone設定→通知→忘れていたでしょう、でオンにしてください。"
            return
        default:
            break
        }

        notifier.postTestNotification { success, errorMessage in
            if success {
                testNotifyMessage = "テスト通知を送りました。バナーが出ない場合は、上の通知ステータスを確認してください。"
            } else {
                testNotifyMessage = errorMessage ?? "テスト通知に失敗しました。"
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

    private var notificationStatusLabel: String {
        switch notificationAuthStatus {
        case .authorized: return "許可"
        case .provisional: return "仮許可"
        case .ephemeral: return "一時許可"
        case .denied: return "拒否"
        case .notDetermined: return "未設定"
        @unknown default: return "不明"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationAuthStatus {
        case .authorized, .provisional, .ephemeral: return .secondary
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .secondary
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
