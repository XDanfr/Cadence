import SwiftUI
import AppKit
import UserNotifications
import ServiceManagement
import CadenceCore

@MainActor final class Model: ObservableObject {
    @Published var state: TimerState
    @Published var preferences: Preferences { didSet { save(); updateSleep() } }
    @Published var sessions: [Session]
    @Published var now = Date()
    @Published var message: String?
    @Published var alarmRinging = false
    private var ticker: Timer?
    private var alarm: NSSound?
    private var activity: NSObjectProtocol?
    private let store: CadenceStore
    let notifications: NotificationCoordinator
    private let notificationClient: SystemNotifications
    @Published var showOnboarding: Bool
    @Published var notificationTestMessage: String?
    @Published var testingNotification = false
    var hasCompletedOnboarding: Bool { store.onboardingCompleted }
    init() {
        let store = CadenceStore()
        self.store = store
        store.migratePreviousDomain(currentBundleID: Bundle.main.bundleIdentifier)
        let client = SystemNotifications()
        notificationClient = client
        notifications = NotificationCoordinator(client: client)
        showOnboarding = !store.onboardingCompleted
        state = store.read("state") ?? TimerState()
        preferences = store.read("preferences") ?? Preferences()
        sessions = store.read("sessions") ?? []
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.tick() } }
        NotificationCenter.default.addObserver(forName: NSColor.systemColorsDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.objectWillChange.send() }
        }
        notifications.onChange = { [weak self] in self?.objectWillChange.send() }
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.refreshNotifications() }
        }
        tick(); updateSleep()
        Task { await refreshNotifications() }
    }
    var remaining: TimeInterval { state.seconds(at: now) }
    var running: Bool { state.deadline != nil }
    var clock: String { let s = Int(ceil(remaining)); return String(format: "%02d:%02d", s / 60, s % 60) }
    var progress: Double { min(1, max(0, 1 - remaining / max(1, state.duration))) }
    var today: [Session] { sessions.filter { Calendar.current.isDateInToday($0.date) } }
    var week: [Session] { sessions.filter { $0.date >= (Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: now)) ?? now) } }
    var sounds: [String] {
        let folder = URL(fileURLWithPath: "/System/Library/Sounds")
        return ["None"] + ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "aiff" }.map { $0.deletingPathExtension().lastPathComponent }.sorted()
    }
    func save() { store.save(state: state, preferences: preferences, sessions: sessions) }
    func tick() {
        now = Date()
        guard running, remaining <= 0 else { return }
        let ended = state.deadline ?? now
        if state.phase == .focus { sessions.insert(Session(date: ended, seconds: state.duration, task: state.task), at: 0) }
        playSound(loop: true)
        state.advance(preferences: preferences, completed: true)
        // Never count unattended cycles after sleep or quit. Start one fresh interval.
        let auto = state.phase == .focus ? preferences.autoFocus : preferences.autoBreak
        if auto { state.start(at: now) }
        save(); scheduleNotification(); updateSleep()
    }
    func toggle() {
        stopAlarm(); now = Date()
        if running { state.pause(at: now) } else { state.start(at: now) }
        save(); scheduleNotification(); updateSleep()
    }
    func reset() { stopAlarm(); state.reset(preferences: preferences); save(); scheduleNotification(); updateSleep() }
    func skip() { stopAlarm(); state.advance(preferences: preferences, completed: false); save(); scheduleNotification(); updateSleep() }
    func select(_ phase: Phase) { stopAlarm(); state.select(phase, preferences: preferences); save(); scheduleNotification(); updateSleep() }
    func extend() { state.extend(by: 300); save(); scheduleNotification() }
    func preset(_ focus: Int, _ short: Int, _ long: Int) { preferences.focusMinutes = focus; preferences.shortMinutes = short; preferences.longMinutes = long; if !running { reset() } }
    func stopAlarm() { alarm?.stop(); alarm = nil; alarmRinging = false }
    func playSound(loop: Bool = false) {
        stopAlarm()
        guard preferences.sound != "None", let sound = NSSound(named: NSSound.Name(preferences.sound)) else { return }
        sound.volume = Float(preferences.volume); sound.loops = loop; sound.play(); alarm = sound; alarmRinging = loop
    }
    func refreshNotifications() async {
        await notifications.refresh()
        scheduleNotification()
    }
    func requestNotifications() {
        Task {
            await notifications.requestPermission()
            scheduleNotification()
        }
    }
    func scheduleNotification() {
        guard preferences.notifications, let deadline = state.deadline, deadline > Date() else {
            notifications.replace(with: nil); return
        }
        notifications.replace(with: IntervalNotification(
            deadline: deadline,
            title: state.phase == .focus ? "Time to breathe" : "Ready for your next focus?",
            body: state.phase == .focus ? "Your focus interval is complete. Take a well-earned break." : "Your break is complete. Return at your own pace."
        ))
    }
    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") { NSWorkspace.shared.open(url) }
    }
    func testNotification() {
        guard !testingNotification else { return }
        testingNotification = true; notificationTestMessage = nil
        Task {
            await notifications.refresh()
            guard notifications.access.permission.canSchedule else { testingNotification = false; return }
            do {
                try await notificationClient.sendTest()
                notificationTestMessage = "Test sent. A banner should appear in a moment; Focus modes and banner settings can hide it."
            } catch { notificationTestMessage = "The test could not be sent: \(error.localizedDescription)" }
            testingNotification = false
        }
    }
    func copyNotificationDiagnostics() {
        let info = """
        Cadence notification diagnostics
        Bundle: \(Bundle.main.bundleIdentifier ?? "none")
        Location: \(Bundle.main.bundleURL.path)
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Permission: \(notifications.access.permission.rawValue)
        Banners enabled: \(notifications.access.alertsEnabled)
        Interval notifications: \(preferences.notifications)
        Error: \(notifications.issue ?? notificationTestMessage ?? "none")
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
    }
    func completeOnboarding(_ draft: Preferences? = nil) {
        if let draft {
            // Do not disturb a running or partly completed interval when replaying setup.
            let untouchedTimer = state.deadline == nil && state.remaining == state.duration
            preferences = draft
            if untouchedTimer { state.reset(preferences: preferences) }
        }
        store.onboardingCompleted = true
        showOnboarding = false
        save(); scheduleNotification(); updateSleep()
    }
    func clearHistory(ids: Set<UUID>) {
        sessions.removeAll { ids.contains($0.id) }; save()
    }
    @discardableResult func resetApp() -> Bool {
        // Unregister before deleting preferences; a failed unregister must remain visible/retryable.
        if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
            do { try SMAppService.mainApp.unregister() }
            catch { message = "Could not turn off launch at login. Nothing was reset. \(error.localizedDescription)"; return false }
        }
        stopAlarm(); notifications.clear()
        notificationTestMessage = nil
        state = TimerState(); sessions = []; preferences = Preferences()
        store.reset()
        now = Date(); save(); updateSleep()
        showOnboarding = true
        return true
    }
    func updateSleep() {
        if let activity { ProcessInfo.processInfo.endActivity(activity); self.activity = nil }
        if preferences.preventSleep && running && state.phase == .focus {
            activity = ProcessInfo.processInfo.beginActivity(options: [.idleSystemSleepDisabled], reason: "Cadence focus interval")
        }
    }
    func loginChanged() {
        do {
            if preferences.launchAtLogin {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                try SMAppService.mainApp.unregister()
            }
        }
        catch { preferences.launchAtLogin = SMAppService.mainApp.status == .enabled; message = "Login item: \(error.localizedDescription)" }
    }
    func musicToggle() {
        // Execute only on an explicit click. macOS prompts for Automation permission.
        let musicRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
        let source = musicRunning ? "tell application \"Music\" to playpause" : "tell application \"Music\" to activate"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error { message = "Music control needs permission in System Settings → Privacy & Security → Automation. \(error[NSAppleScript.errorMessage] ?? "")" }
    }
    func exportHistory() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "Cadence-history.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let formatter = ISO8601DateFormatter()
        let rows = sessions.map { "\(formatter.string(from: $0.date)),\(Int($0.seconds)),\"\($0.task.replacingOccurrences(of: "\"", with: "\"\""))\"" }
        do { try (["date,seconds,task"] + rows).joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8) }
        catch { message = error.localizedDescription }
    }
}
