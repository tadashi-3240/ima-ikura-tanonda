import Foundation
import UserNotifications

/// ローカル通知（専用音ピロリローン）。読み上げは第5段階。
@MainActor
final class ReminderNotifier {
    static let soundFileName = "piroriron.caf"
    static let categoryId = "approach.reminder"

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func postApproachNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = "忘れていたでしょう？"
        content.body = "\(reminder.task)予定ですよ！"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(Self.soundFileName))
        content.categoryIdentifier = Self.categoryId
        content.userInfo = ["reminderId": reminder.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "approach-\(reminder.id.uuidString)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil // 即時
        )
        UNUserNotificationCenter.current().add(request)
    }
}
