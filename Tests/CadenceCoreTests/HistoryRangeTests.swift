import XCTest
@testable import CadenceCore

final class HistoryRangeTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }
    private func date(_ year: Int = 2026, _ month: Int = 3, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
    func testTodayIncludesEntireDSTDayButNotNextMidnight() throws {
        let now = date(2026, 3, 29, 12)
        let range = try XCTUnwrap(HistoryRange(scope: .today, now: now, from: now, through: now, calendar: calendar))
        XCTAssertEqual(range.end!.timeIntervalSince(range.start!), 23 * 3600)
        XCTAssertTrue(range.contains(date(2026, 3, 29)))
        XCTAssertTrue(range.contains(date(2026, 3, 29, 23)))
        XCTAssertFalse(range.contains(date(2026, 3, 30)))
        XCTAssertFalse(range.contains(date(2026, 3, 28, 23)))
    }
    func testLastSevenDaysIncludesTodayAndPreviousSixOnly() throws {
        let now = date(2026, 3, 30, 12)
        let range = try XCTUnwrap(HistoryRange(scope: .lastSevenDays, now: now, from: now, through: now, calendar: calendar))
        XCTAssertTrue(range.contains(date(2026, 3, 24)))
        XCTAssertFalse(range.contains(date(2026, 3, 23, 23)))
        XCTAssertTrue(range.contains(date(2026, 3, 30, 23)))
        XCTAssertFalse(range.contains(date(2026, 3, 31)))
    }
    func testCustomRangeIncludesBothDatesAndRejectsReversedRange() throws {
        let now = date(2026, 10, 25, 12)
        let range = try XCTUnwrap(HistoryRange(scope: .custom, now: now, from: date(2026, 10, 25, 12), through: date(2026, 10, 25, 16), calendar: calendar))
        XCTAssertEqual(range.end!.timeIntervalSince(range.start!), 25 * 3600)
        XCTAssertTrue(range.contains(date(2026, 10, 25, 0)))
        XCTAssertFalse(range.contains(date(2026, 10, 26)))
        XCTAssertNil(HistoryRange(scope: .custom, now: now, from: date(2026, 10, 26), through: date(2026, 10, 25), calendar: calendar))
    }
    func testAllHistoryIncludesEveryDate() throws {
        let now = Date()
        let range = try XCTUnwrap(HistoryRange(scope: .all, now: now, from: now, through: now))
        XCTAssertTrue(range.contains(.distantPast)); XCTAssertTrue(range.contains(.distantFuture))
    }
}
