import Foundation
import UserNotifications
import CadenceCore

@MainActor final class SystemNotifications: NotificationClient {
    private let center = UNUserNotificationCenter.current()
    private let intervalID = "cadence.interval"
    private let testID = "cadence.test"
    func settings() async -> NotificationAccess {
        let settings = await center.notificationSettings()
        let permission: NotificationPermission
        switch settings.authorizationStatus {
        case .notDetermined: permission = .notDetermined
        case .denied: permission = .denied
        case .authorized: permission = .authorised
        case .provisional: permission = .provisional
        case .ephemeral: permission = .authorised
        @unknown default: permission = .unavailable
        }
        return NotificationAccess(permission: permission, alertsEnabled: settings.alertSetting == .enabled)
    }
    func requestPermission() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
    }
    func add(_ notification: IntervalNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title; content.body = notification.body
        // Cadence plays its selected Apple alarm; the banner must not double the sound.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, notification.deadline.timeIntervalSinceNow), repeats: false)
        try await center.add(UNNotificationRequest(identifier: intervalID, content: content, trigger: trigger))
    }
    func removeInterval() { center.removePendingNotificationRequests(withIdentifiers: [intervalID]) }
    func removeAllCadenceNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [intervalID, testID])
        center.removeDeliveredNotifications(withIdentifiers: [intervalID, testID])
    }
    func removeTest() { center.removePendingNotificationRequests(withIdentifiers: [testID]) }
    func sendTest() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Cadence is ready"
        content.body = "Your interval reminders will appear like this."
        try await center.add(UNNotificationRequest(identifier: testID, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)))
    }
}
