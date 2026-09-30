import Foundation

public enum Phase: String, Codable, CaseIterable {
    case focus, shortBreak, longBreak
    public var title: String { switch self { case .focus: return "Focus"; case .shortBreak: return "Short break"; case .longBreak: return "Long break" } }
}
public struct Preferences: Codable, Equatable {
    public var focusMinutes = 25
    public var shortMinutes = 5
    public var longMinutes = 15
    public var rounds = 4
    public var dailyGoal = 8
    public var autoFocus = false
    public var autoBreak = true
    public var sound = "Glass"
    public var volume = 0.7
    public var notifications = true
    public var preventSleep = false
    public var launchAtLogin = false
    public var appearance = "System"
    public init() {}
    public func duration(_ phase: Phase) -> TimeInterval {
        TimeInterval(max(1, min(180, phase == .focus ? focusMinutes : phase == .shortBreak ? shortMinutes : longMinutes)) * 60)
    }
}
public struct Session: Codable, Identifiable {
    public var id = UUID()
    public var date: Date
    public var seconds: TimeInterval
    public var task: String
    public init(date: Date, seconds: TimeInterval, task: String) { self.date = date; self.seconds = seconds; self.task = task }
}
public struct TimerState: Codable {
    public var phase: Phase = .focus
    public var remaining: TimeInterval = 1500
    public var duration: TimeInterval = 1500
    public var deadline: Date?
    public var completedRounds = 0
    public var task = ""
    public init() {}
    public func seconds(at now: Date) -> TimeInterval { max(0, deadline.map { $0.timeIntervalSince(now) } ?? remaining) }
    public mutating func start(at now: Date) { if deadline == nil { deadline = now.addingTimeInterval(remaining) } }
    public mutating func pause(at now: Date) { remaining = seconds(at: now); deadline = nil }
    public mutating func reset(preferences: Preferences) { deadline = nil; duration = preferences.duration(phase); remaining = duration }
    public mutating func select(_ newPhase: Phase, preferences: Preferences) { phase = newPhase; reset(preferences: preferences) }
    public mutating func advance(preferences: Preferences, completed: Bool) {
        if phase == .focus {
            if completed { completedRounds += 1 }
            phase = completed && completedRounds % max(1, preferences.rounds) == 0 ? .longBreak : .shortBreak
        } else { phase = .focus }
        reset(preferences: preferences)
    }
    public mutating func extend(by seconds: TimeInterval) { duration += seconds; remaining += seconds; deadline = deadline?.addingTimeInterval(seconds) }
}
