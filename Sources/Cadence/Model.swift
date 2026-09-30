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
    private let defaults = UserDefaults.standard
    private let notificationID = "cadence.interval"
    init() {
        Self.migratePreviousDefaults()
        state = Self.read("state") ?? TimerState()
        preferences = Self.read("preferences") ?? Preferences()
        sessions = Self.read("sessions") ?? []
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.tick() } }
        NotificationCenter.default.addObserver(forName: NSColor.systemColorsDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.objectWillChange.send() }
        }
        tick(); updateSleep()
    }
    private static func migratePreviousDefaults() {
        guard Bundle.main.bundleIdentifier == "me.xdan.Cadence",
              let previous = UserDefaults.standard.persistentDomain(forName: "uk.xdan.Cadence") else { return }
        // Preserve local data when upgrading across the bundle-ID correction.
        // Existing values in the new domain always win.
        for key in ["state", "preferences", "sessions"] where UserDefaults.standard.object(forKey: key) == nil {
            if let value = previous[key] { UserDefaults.standard.set(value, forKey: key) }
        }
    }
    static func read<T: Decodable>(_ key: String) -> T? { UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) } }
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
    func save() {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: "state") }
        if let data = try? JSONEncoder().encode(preferences) { defaults.set(data, forKey: "preferences") }
        if let data = try? JSONEncoder().encode(sessions) { defaults.set(data, forKey: "sessions") }
    }
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
    func requestNotifications() {
        Task {
            do { let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]); if !granted { message = "Notifications are disabled. Enable Cadence in System Settings → Notifications." }; scheduleNotification() }
            catch { message = error.localizedDescription }
        }
    }
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        guard preferences.notifications, let deadline = state.deadline, deadline > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = state.phase == .focus ? "Time to breathe" : "Ready for your next focus?"
        content.body = state.phase == .focus ? "Your focus interval is complete. Take a well-earned break." : "Your break is complete. Return at your own pace."
        // The selected Apple sound is played by the app; avoid two simultaneous alarms.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger))
    }
    func updateSleep() {
        if let activity { ProcessInfo.processInfo.endActivity(activity); self.activity = nil }
        if preferences.preventSleep && running && state.phase == .focus {
            activity = ProcessInfo.processInfo.beginActivity(options: [.idleSystemSleepDisabled], reason: "Cadence focus interval")
        }
    }
    func loginChanged() {
        do { if preferences.launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
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
