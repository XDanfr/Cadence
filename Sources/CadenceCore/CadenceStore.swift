import Foundation

/// Owns only Cadence's keys. A full reset must never import the old bundle's history again.
public final class CadenceStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public var onboardingCompleted: Bool {
        get { defaults.bool(forKey: "onboardingCompleted") }
        set { defaults.set(newValue, forKey: "onboardingCompleted") }
    }
    public func read<T: Decodable>(_ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    public func save(state: TimerState, preferences: Preferences, sessions: [Session]) {
        write(state, key: "state"); write(preferences, key: "preferences"); write(sessions, key: "sessions")
    }
    private func write<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
    public func migratePreviousDomain(currentBundleID: String?) {
        guard currentBundleID == "me.xdan.Cadence", !defaults.bool(forKey: "legacyDefaultsMigrated") else { return }
        if let previous = defaults.persistentDomain(forName: "uk.xdan.Cadence") {
            for key in ["state", "preferences", "sessions"] where defaults.object(forKey: key) == nil {
                if let value = previous[key] { defaults.set(value, forKey: key) }
            }
        }
        defaults.set(true, forKey: "legacyDefaultsMigrated")
    }
    public func reset() {
        // Persist empty/default values rather than deleting the domain and re-importing old data.
        defaults.set(true, forKey: "legacyDefaultsMigrated")
        onboardingCompleted = false
        save(state: TimerState(), preferences: Preferences(), sessions: [])
    }
}
