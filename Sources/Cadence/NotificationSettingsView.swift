import SwiftUI
import CadenceCore

struct NotificationSettingsView: View {
    @EnvironmentObject private var model: Model
    var showToggle = true
    private var permission: NotificationPermission { model.notifications.access.permission }
    private var status: String {
        if model.notifications.requesting { return "Waiting for macOS…" }
        switch permission {
        case .unknown: return "Checking notification access…"
        case .notDetermined: return "Notification access has not been requested."
        case .denied: return "Notification access is off in System Settings."
        case .authorised: return model.notifications.access.alertsEnabled ? "Notification access is allowed." : "Access is allowed, but banners are off in System Settings."
        case .provisional: return "Quiet notification access is allowed. Enable banners in System Settings."
        case .unavailable: return "Notification access is unavailable for this application."
        }
    }
    var body: some View {
        if showToggle {
            Toggle("Show interval notifications", isOn: $model.preferences.notifications)
                .onChange(of: model.preferences.notifications) { _, enabled in
                    if enabled && permission == .notDetermined { model.requestNotifications() }
                    else { model.scheduleNotification() }
                }
        }
        Label(status, systemImage: permission.canSchedule ? "checkmark.circle.fill" : "bell.badge")
            .foregroundStyle(permission.canSchedule ? model.accentColor : .secondary)
            .accessibilityIdentifier("notificationStatus")
        HStack {
            if permission == .notDetermined {
                Button(model.notifications.requesting ? "Requesting access…" : "Allow notifications…") { model.requestNotifications() }
                    .disabled(model.notifications.requesting)
            }
            if permission != .unknown {
                Button("Open System Settings…") { model.openNotificationSettings() }
            }
            if permission.canSchedule {
                Button("Send test notification") { model.testNotification() }
                    .disabled(model.testingNotification)
            }
        }
        if let issue = model.notifications.issue {
            Text(issue).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            Button("Copy notification diagnostics") { model.copyNotificationDiagnostics() }
        }
        if let result = model.notificationTestMessage {
            Text(result).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
        }
        Text("Focus modes can silence notifications. Cadence must be running to play its alarm; scheduled notifications can arrive while it is closed.")
            .font(.caption).foregroundStyle(.secondary)
    }
}
