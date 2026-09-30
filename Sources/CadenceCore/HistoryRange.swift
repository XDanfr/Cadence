import Foundation

public enum HistoryScope: String, CaseIterable, Identifiable {
    case today, lastSevenDays, custom, all
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .today: return "Today"
        case .lastSevenDays: return "Last 7 days"
        case .custom: return "Date range"
        case .all: return "All history"
        }
    }
}
/// Uses local calendar days and a half-open range, including the whole last day across DST.
public struct HistoryRange {
    public let start: Date?
    public let end: Date?
    public init?(scope: HistoryScope, now: Date, from: Date, through: Date, calendar: Calendar = .current) {
        if scope == .all { start = nil; end = nil; return }
        let today = calendar.startOfDay(for: now)
        let first: Date
        let last: Date
        switch scope {
        case .today: first = today; last = today
        case .lastSevenDays:
            guard let day = calendar.date(byAdding: .day, value: -6, to: today) else { return nil }
            first = day; last = today
        case .custom: first = calendar.startOfDay(for: from); last = calendar.startOfDay(for: through)
        case .all: return nil
        }
        guard first <= last, let next = calendar.date(byAdding: .day, value: 1, to: last) else { return nil }
        start = first; end = next
    }
    public func contains(_ date: Date) -> Bool {
        if let start, date < start { return false }
        if let end, date >= end { return false }
        return true
    }
}
