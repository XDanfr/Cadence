import Foundation

public enum NotificationPermission: String, Sendable {
    case unknown, notDetermined, denied, authorised, provisional, unavailable
    public var canSchedule: Bool { self == .authorised || self == .provisional }
}
public struct NotificationAccess: Sendable {
    public var permission: NotificationPermission
    public var alertsEnabled: Bool
    public init(permission: NotificationPermission, alertsEnabled: Bool = true) {
        self.permission = permission; self.alertsEnabled = alertsEnabled
    }
}
public struct IntervalNotification: Equatable, Sendable {
    public var deadline: Date
    public var title: String
    public var body: String
    public init(deadline: Date, title: String, body: String) {
        self.deadline = deadline; self.title = title; self.body = body
    }
}
@MainActor public protocol NotificationClient: AnyObject {
    func settings() async -> NotificationAccess
    func requestPermission() async throws
    func add(_ notification: IntervalNotification) async throws
    func removeInterval()
    func removeAllCadenceNotifications()
}

/// Serialises replacements so an older async request cannot resurrect a paused/reset timer.
@MainActor public final class NotificationCoordinator {
    public private(set) var access = NotificationAccess(permission: .unknown)
    public private(set) var requesting = false
    public private(set) var issue: String?
    public var onChange: (() -> Void)?
    private let client: any NotificationClient
    private var revision = 0
    private var tail: Task<Void, Never>?
    public init(client: any NotificationClient) { self.client = client }
    public func refresh() async {
        access = await client.settings()
        if access.permission.canSchedule { issue = nil }
        onChange?()
    }
    public func requestPermission() async {
        guard !requesting else { return }
        requesting = true; issue = nil; onChange?()
        await refresh()
        // macOS only shows a prompt for an undecided permission. Denials need System Settings.
        if access.permission == .notDetermined {
            do { try await client.requestPermission() }
            catch {
                await refresh()
                issue = access.permission == .denied
                    ? "Notification access is off in System Settings."
                    : "macOS could not request notification access for this copy of Cadence. Install the packaged app in Applications, reopen it and try again. Details: \(error.localizedDescription)"
            }
            if issue == nil {
                await refresh()
                if access.permission == .notDetermined {
                    issue = "macOS did not record a permission decision. Reopen the packaged app from Applications and try again."
                }
            }
        }
        requesting = false; onChange?()
    }
    @discardableResult public func replace(with notification: IntervalNotification?) -> Task<Void, Never> {
        revision += 1
        let current = revision
        let previous = tail
        client.removeInterval()
        let task = Task { [weak self] in
            await previous?.value
            guard let self, current == self.revision else { return }
            self.client.removeInterval()
            guard let notification else { return }
            await self.refresh()
            guard current == self.revision, self.access.permission.canSchedule,
                  notification.deadline > Date() else { return }
            do { try await self.client.add(notification) }
            catch {
                guard current == self.revision else { self.client.removeInterval(); return }
                await self.refresh()
                self.issue = "The notification could not be scheduled: \(error.localizedDescription)"
                self.onChange?()
            }
            if current != self.revision { self.client.removeInterval() }
        }
        tail = task
        return task
    }
    public func clear() {
        replace(with: nil)
        client.removeAllCadenceNotifications()
        issue = nil; onChange?()
    }
}
