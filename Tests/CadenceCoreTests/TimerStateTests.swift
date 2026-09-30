import XCTest
@testable import CadenceCore

final class TimerStateTests: XCTestCase {
    func testPauseResumeUsesDeadline() {
        var state = TimerState()
        let start = Date(timeIntervalSince1970: 1000)
        state.start(at: start)
        XCTAssertEqual(state.seconds(at: start.addingTimeInterval(90)), 1410)
        state.pause(at: start.addingTimeInterval(90))
        XCTAssertNil(state.deadline)
        state.start(at: start.addingTimeInterval(3600))
        XCTAssertEqual(state.seconds(at: start.addingTimeInterval(3610)), 1400)
    }
    func testLongBreakCadenceAndSkippedFocus() {
        var state = TimerState(); let preferences = Preferences()
        for round in 1...4 {
            state.advance(preferences: preferences, completed: true)
            XCTAssertEqual(state.completedRounds, round)
            XCTAssertEqual(state.phase, round == 4 ? .longBreak : .shortBreak)
            state.advance(preferences: preferences, completed: true)
            XCTAssertEqual(state.phase, .focus)
        }
        state.advance(preferences: preferences, completed: false)
        XCTAssertEqual(state.completedRounds, 4)
        XCTAssertEqual(state.phase, .shortBreak)
    }
    func testSleepAndPersistence() throws {
        var state = TimerState()
        let now = Date(timeIntervalSince1970: 1000)
        state.start(at: now)
        let restored = try JSONDecoder().decode(TimerState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.seconds(at: now.addingTimeInterval(7200)), 0)
        XCTAssertEqual(restored.deadline, state.deadline)
    }
    func testExtensionKeepsProgressConsistent() {
        var state = TimerState(); let now = Date()
        state.start(at: now); state.extend(by: 300)
        XCTAssertEqual(state.duration, 1800)
        XCTAssertEqual(state.seconds(at: now), 1800, accuracy: 0.01)
        state.pause(at: now.addingTimeInterval(60)); state.extend(by: 300)
        XCTAssertEqual(state.remaining, 2040, accuracy: 0.01)
    }
    func testCustomIntervalsAndReset() {
        var preferences = Preferences(); preferences.focusMinutes = 50; preferences.rounds = 2
        var state = TimerState(); state.reset(preferences: preferences)
        XCTAssertEqual(state.remaining, 3000)
        state.select(.longBreak, preferences: preferences)
        XCTAssertEqual(state.remaining, 900)
        preferences.focusMinutes = -1
        XCTAssertEqual(preferences.duration(.focus), 60)
    }
}
