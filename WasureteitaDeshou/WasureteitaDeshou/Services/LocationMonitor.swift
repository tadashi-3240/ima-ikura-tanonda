import CoreLocation
import Foundation
import Combine

/// 予定の円形ジオフェンス監視。Always 許可でバックグラウンドでも進入通知。
@MainActor
final class LocationMonitor: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var lastErrorMessage: String?

    private let manager = CLLocationManager()
    private let notifier = ReminderNotifier()
    private var reminderLookup: [String: Reminder] = [:]
    /// 同じ領域にいるあいだの連打を防ぐ（退出でクリア）
    private var notifiedWhileInside: Set<String> = []

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.pausesLocationUpdatesAutomatically = true
        manager.allowsBackgroundLocationUpdates = false
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
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
    }

    func stopMonitoring(id: UUID) {
        let key = id.uuidString
        reminderLookup.removeValue(forKey: key)
        notifiedWhileInside.remove(key)
        for region in manager.monitoredRegions where region.identifier == key {
            manager.stopMonitoring(for: region)
        }
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
        notifiedWhileInside.insert(identifier)
        notifier.postApproachNotification(for: reminder)
    }
}

extension LocationMonitor: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            // 許可が付いたら再同期は呼び出し側（App）でも行う
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
        }
    }
}
