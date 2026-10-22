import SwiftUI

/// 内容確認 → MapKit 検索 → 候補／地図 → 予定保存。同じタブ内の phase 切替（cover なし）。
struct SimpleUtteranceConfirmView: View {
    let rawText: String
    var onBack: () -> Void

    @EnvironmentObject private var reminderStore: ReminderStore
    @EnvironmentObject private var draftStore: DraftUtteranceStore
    @EnvironmentObject private var notifySettings: AppNotifySettings
    @EnvironmentObject private var locationMonitor: LocationMonitor

    @StateObject private var locationProvider = UserLocationProvider()

    @State private var placeText: String
    @State private var taskText: String
    @State private var phase: Phase = .review
    @State private var candidates: [PlaceCandidate] = []
    @State private var selected: PlaceCandidate?
    @State private var errorMessage: String?
    @State private var showPermissionSheet = false
    @State private var pendingSaveAfterPermission = false

    private let search = PlaceSearchService()

    private enum Phase: Equatable {
        case review
        case searching
        case candidates
        case map
        case confirm
        case saved
    }

    init(rawText: String, onBack: @escaping () -> Void) {
        self.rawText = rawText
        self.onBack = onBack
        let parsed = UtteranceParser.parse(rawText)
        _placeText = State(initialValue: parsed.placePhrase)
        _taskText = State(initialValue: parsed.taskPhrase)
    }

    var body: some View {
        Group {
            switch phase {
            case .review, .searching:
                reviewContent
            case .candidates:
                PlaceCandidateListView(
                    candidates: candidates,
                    onSelect: { candidate in
                        selected = candidate
                        phase = .confirm
                    },
                    onPickOnMap: {
                        phase = .map
                    }
                )
            case .map:
                MapPlacePickerView(
                    initialCoordinate: locationProvider.coordinate,
                    onConfirm: { candidate in
                        selected = candidate
                        phase = .confirm
                    }
                )
            case .confirm:
                registerConfirmContent
            case .saved:
                savedContent
            }
        }
        .navigationTitle(phaseTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPermissionSheet) {
            LocationNotifyPermissionView {
                showPermissionSheet = false
                if pendingSaveAfterPermission {
                    pendingSaveAfterPermission = false
                    commitReminder()
                }
            }
            .environmentObject(locationMonitor)
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .review, .searching: return "内容の確認"
        case .candidates: return "場所の候補"
        case .map: return "地図から指定"
        case .confirm: return "登録の確認"
        case .saved: return "登録完了"
        }
    }

    private var reviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("build: stage3-geo-1")
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
                        .disabled(phase == .searching)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("用事")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("例：牛乳を買う", text: $taskText)
                        .font(.system(size: 22))
                        .textFieldStyle(.roundedBorder)
                        .disabled(phase == .searching)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                }

                if phase == .searching {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("場所を検索しています…")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                } else {
                    Button(action: startSearch) {
                        Text(
                            placeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "地図から場所を指定"
                                : "場所を検索して進む"
                        )
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("BrandAccent"))
                    .disabled(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if !placeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("検索せず地図から指定") {
                            phase = .map
                        }
                        .font(.system(size: 17))
                        .frame(maxWidth: .infinity)
                    }

                    Button(action: onBack) {
                        Text("戻る")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
    }

    private var registerConfirmContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("build: stage3-geo-1")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let selected {
                    labeled("場所", selected.name)
                    if !selected.address.isEmpty {
                        labeled("住所", selected.address)
                    }
                }
                labeled("用事", taskText)
                labeled("通知距離", "\(notifySettings.defaultNotifyDistanceMeters) m（設定で変更可）")

                Text("登録すると、この距離の目安で近づいたときに通知します（正確な距離は保証しません）。")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Button(action: saveReminder) {
                    Text("予定に登録する")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("BrandAccent"))
                .disabled(selected == nil)

                Button("場所を選び直す") {
                    if candidates.count > 1 {
                        phase = .candidates
                    } else {
                        phase = .map
                    }
                }
                .font(.system(size: 17))
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    private var savedContent: some View {
        VStack(spacing: 24) {
            Text("build: stage3-geo-1")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color("BrandAccent"))
            Text("予定を登録しました")
                .font(.system(size: 26, weight: .bold))
            Text("場所に近づくと「忘れていたでしょう？」と通知します。「予定一覧」から距離の変更・削除ができます。")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("登録に戻る") {
                draftStore.clearAll()
                onBack()
            }
            .font(.system(size: 20, weight: .semibold))
            .buttonStyle(.borderedProminent)
            .tint(Color("BrandAccent"))

            Spacer()
        }
        .padding(28)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .medium))
        }
    }

    private func startSearch() {
        errorMessage = nil
        let place = placeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else { return }

        if place.isEmpty {
            phase = .map
            return
        }

        phase = .searching
        locationProvider.requestWhenInUseIfNeeded()
        Task {
            let near = await locationProvider.currentCoordinate()
            do {
                let results = try await search.search(query: place, near: near)
                candidates = results
                if results.isEmpty {
                    phase = .map
                } else if results.count == 1 {
                    selected = results[0]
                    phase = .confirm
                } else {
                    phase = .candidates
                }
            } catch {
                errorMessage = error.localizedDescription
                phase = .review
            }
        }
    }

    private func saveReminder() {
        guard selected != nil else { return }
        locationMonitor.refreshAuthorizationStatus()
        // Always 未取得なら説明シート。「あとで」でも登録自体は進める。
        if locationMonitor.authorizationStatus != .authorizedAlways {
            pendingSaveAfterPermission = true
            showPermissionSheet = true
            return
        }
        commitReminder()
    }

    private func commitReminder() {
        guard let selected else { return }
        let reminder = Reminder(
            placeName: selected.name,
            address: selected.address,
            task: taskText.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: selected.latitude,
            longitude: selected.longitude,
            rawUtterance: rawText,
            notifyDistanceMeters: notifySettings.defaultNotifyDistanceMeters
        )
        reminderStore.add(reminder)
        phase = .saved
    }
}

#Preview {
    let monitor = LocationMonitor()
    return NavigationStack {
        SimpleUtteranceConfirmView(rawText: "金古のセブンイレブンで牛乳を買う") {}
    }
    .environmentObject(DraftUtteranceStore())
    .environmentObject(AppNotifySettings())
    .environmentObject(monitor)
    .environmentObject(ReminderStore(locationMonitor: monitor))
}
