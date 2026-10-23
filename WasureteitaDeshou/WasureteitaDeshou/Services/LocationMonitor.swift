import CoreLocation
import Foundation
import Combine

/// 予定の円形ジオフェンス監視。Always 許可でバックグラウンドでも進入通知。
@MainActor
final class LocationMonitor: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var lastErrorMessage: String?
    /// 現在システムに渡している監視領域の件数
    @Published private(set) var monitoredRegionCount: Int = 0

    private let manager = CLLocationManager()
    private let notifier = ReminderNotifier()
    private var reminderLookup: [String: Reminder] = [:]
    /// 同じ領域にいるあいだの連打を防ぐ（退出でクリア）。通知成功後のみセット。
    private var notifiedWhileInside: Set<String> = []

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.pausesLocationUpdatesAutomatically = true
        // 常時 GPS（continuous）は使わない。領域監視のみ。
        manager.allowsBackgroundLocationUpdates = false
        refreshMonitoredCount()
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
        refreshMonitoredCount()
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    /// 保存済み予定と監視を同期する。
    func sync(reminders: [Reminder]) {
        reminderLookup = Dictionary(uniqueKeysWithValues: reminders.map { ($0.id.uuidString, $0) })

        let wanted = Set(reminders.map(\.id.uuidString))
        for region in manager.monitoredRegions {
            guard let circular = region as? CLCircularRegion else { continue }
            if !wanted.contains(circular.identifier) {
                manager.stopMonitoring(for: circular)
                notifiedWhileInside.remove(circular.identifier)
            }
        }

        for reminder in reminders {
            startOrUpdate(reminder: reminder)
        }
        refreshMonitoredCount()
    }

    func stopMonitoring(id: UUID) {
        let key = id.uuidString
        reminderLookup.removeValue(forKey: key)
        notifiedWhileInside.remove(key)
        for region in manager.monitoredRegions where region.identifier == key {
            manager.stopMonitoring(for: region)
        }
        refreshMonitoredCount()
    }

    /// フォアグラウンド復帰時など、監視中の全領域の内外を再問い合わせする。
    func requestStateForAllMonitoredRegions() {
        for region in manager.monitoredRegions {
            manager.requestState(for: region)
        }
        refreshMonitoredCount()
    }

    private func refreshMonitoredCount() {
        monitoredRegionCount = manager.monitoredRegions.count
    }

    private func startOrUpdate(reminder: Reminder) {
        let key = reminder.id.uuidString
        reminderLookup[key] = reminder

        let radius = CLLocationDistance(max(100, AppNotifySettings.clamp(reminder.notifyDistanceMeters)))
        let center = CLLocationCoordinate2D(latitude: reminder.latitude, longitude: reminder.longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: key)
        region.notifyOnEntry = true
        region.notifyOnExit = true

        // 既存を差し替え
        for existing in manager.monitoredRegions where existing.identifier == key {
            manager.stopMonitoring(for: existing)
        }

        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            lastErrorMessage = "この端末では領域監視を利用できません。"
            return
        }

        let status = manager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            lastErrorMessage = "位置情報の許可が必要です。"
            return
        }

        manager.startMonitoring(for: region)
        manager.requestState(for: region)
    }

    private func handleEnter(identifier: String) {
        guard let reminder = reminderLookup[identifier] else { return }
        guard !notifiedWhileInside.contains(identifier) else { return }
        // 成功するまでフラグを立てない（失敗時は再試行可能）
        notifier.postApproachNotification(for: reminder) { [weak self] success, errorMessage in
            guard let self else { return }
            if success {
                self.notifiedWhileInside.insert(identifier)
            } else {
                self.lastErrorMessage = errorMessage ?? "通知の送信に失敗しました。"
            }
        }
    }
}

extension LocationMonitor: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            self.refreshMonitoredCount()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            self.handleEnter(identifier: region.identifier)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            self.notifiedWhileInside.remove(region.identifier)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        Task { @MainActor in
            if state == .inside {
                self.handleEnter(identifier: region.identifier)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            self.lastErrorMessage = "位置の監視を開始できませんでした。"
            self.refreshMonitoredCount()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Task { @MainActor in
            self.refreshMonitoredCount()
        }
    }
}
