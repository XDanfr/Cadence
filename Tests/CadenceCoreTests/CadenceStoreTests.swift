import XCTest
@testable import CadenceCore

final class CadenceStoreTests: XCTestCase {
    func testResetPersistsDefaultsAndReturnsToOnboardingWithoutResurrectingData() throws {
        let name = "CadenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = CadenceStore(defaults: defaults)
        var state = TimerState(); state.task = "Private intention"; state.start(at: Date())
        var preferences = Preferences(); preferences.launchAtLogin = true; preferences.focusMinutes = 50
        store.save(state: state, preferences: preferences, sessions: [Session(date: Date(), seconds: 1500, task: "Work")])
        store.onboardingCompleted = true
        store.reset()
        let restored = CadenceStore(defaults: defaults)
        XCTAssertFalse(restored.onboardingCompleted)
        XCTAssertTrue(defaults.bool(forKey: "legacyDefaultsMigrated"))
        let timer: TimerState = try XCTUnwrap(restored.read("state"))
        let settings: Preferences = try XCTUnwrap(restored.read("preferences"))
        let sessions: [Session] = try XCTUnwrap(restored.read("sessions"))
        XCTAssertNil(timer.deadline); XCTAssertEqual(timer.task, "")
        XCTAssertEqual(settings, Preferences()); XCTAssertTrue(sessions.isEmpty)
        restored.migratePreviousDomain(currentBundleID: "me.xdan.Cadence")
        let afterMigration: [Session] = try XCTUnwrap(restored.read("sessions"))
        XCTAssertTrue(afterMigration.isEmpty)
    }
    func testCompletingOrReplayingSetupDoesNotEraseHistory() throws {
        let name = "CadenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = CadenceStore(defaults: defaults)
        store.save(state: TimerState(), preferences: Preferences(), sessions: [Session(date: Date(), seconds: 1500, task: "Work")])
        store.onboardingCompleted = true
        let restored = CadenceStore(defaults: defaults)
        XCTAssertTrue(restored.onboardingCompleted)
        let sessions: [Session] = try XCTUnwrap(restored.read("sessions"))
        XCTAssertEqual(sessions.count, 1)
    }
}
