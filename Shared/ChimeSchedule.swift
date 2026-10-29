import Foundation

/// A time of day to the minute, e.g. 9:00 AM or 17:30.
struct TimeOfDay: Codable, Hashable, Comparable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int = 0) {
        self.hour = hour
        self.minute = minute
    }

    init(minuteOfDay: Int) {
        self.init(hour: minuteOfDay / 60, minute: minuteOfDay % 60)
    }

    init(of date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour!, minute: components.minute!)
    }

    /// The last minute of the day, 11:59 PM.
    static let lastMinute = TimeOfDay(hour: 23, minute: 59)

    /// Minutes since midnight, 0...1439.
    var minuteOfDay: Int { hour * 60 + minute }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.minuteOfDay < rhs.minuteOfDay }
}

/// Matches `Calendar` weekday numbers: 1 = Sunday … 7 = Saturday.
enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Self { self }

    init(of date: Date, calendar: Calendar) {
        self.init(rawValue: calendar.component(.weekday, from: date))!
    }

    /// "Mon"
    var shortLabel: String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][rawValue - 1]
    }

    /// "M", for the day picker.
    var letter: String { String(shortLabel.prefix(1)) }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A window of the day when chimes fire while When is Scheduled. See docs/SPEC.md → Schedules.
struct ChimeSchedule: Codable, Equatable, Identifiable {
    var id = UUID()
    var isEnabled = true
    var start = TimeOfDay(hour: 9)
    /// The last chime time; a chime at the end time fires. After `start` in saved schedules.
    var end = TimeOfDay(hour: 17)
    /// Starts with every day; saved schedules have at least one.
    var weekdays = Set(Weekday.allCases)
    /// Set to the next midnight when turned off for today, so it turns back on by itself.
    var skippedUntil: Date?
}

extension ChimeSchedule {
    /// Decodes field by field. Schedules saved by earlier builds could have no end time (until
    /// midnight, now 11:59 PM) or no days (every day, now all seven).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ChimeSchedule()
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? defaults.id
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? defaults.isEnabled
        start = try container.decodeIfPresent(TimeOfDay.self, forKey: .start) ?? defaults.start
        end = try container.decodeIfPresent(TimeOfDay.self, forKey: .end) ?? .lastMinute
        let weekdays = try container.decodeIfPresent(Set<Weekday>.self, forKey: .weekdays) ?? []
        self.weekdays = weekdays.isEmpty ? defaults.weekdays : weekdays
        skippedUntil = try container.decodeIfPresent(Date.self, forKey: .skippedUntil)
    }

    func applies(to weekday: Weekday) -> Bool {
        weekdays.contains(weekday)
    }

    /// Whether `time` is inside the window. Both the start and the end are included.
    func contains(_ time: TimeOfDay) -> Bool {
        start <= time && time <= end
    }

    func isSkipped(at date: Date) -> Bool {
        skippedUntil.map { date < $0 } ?? false
    }

    /// Whether today's window has passed.
    func hasEnded(at date: Date, calendar: Calendar) -> Bool {
        TimeOfDay(of: date, calendar: calendar) > end
    }

    var endsAfterStart: Bool { end > start }

    /// Whether the editor can save it: the end is after the start, and at least one day is selected.
    var isValid: Bool { endsAfterStart && !weekdays.isEmpty }

    /// Turns the schedule off for the rest of `date`'s day, or back on.
    mutating func skipToday(_ skip: Bool, at date: Date, calendar: Calendar) {
        skippedUntil = skip ? calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) : nil
    }
}

// MARK: - Which chimes fire

extension ChimeSettings {
    /// Schedules that can chime: their own toggle is on.
    var activeSchedules: [ChimeSchedule] {
        schedules.filter(\.isEnabled)
    }

    /// Whether a chime at `date` fires. See docs/SPEC.md → Which chimes fire.
    func chimes(at date: Date, calendar: Calendar) -> Bool {
        guard isEnabled else { return false }
        if isInfinite { return true }
        let weekday = Weekday(of: date, calendar: calendar)
        let time = TimeOfDay(of: date, calendar: calendar)
        return activeSchedules.contains { $0.applies(to: weekday) && $0.contains(time) && !$0.isSkipped(at: date) }
    }

    /// Whether a chime at `time` on `weekday` fires every week, ignoring schedules turned off for today.
    func chimes(on weekday: Weekday, at time: TimeOfDay) -> Bool {
        guard isEnabled else { return false }
        if isInfinite { return true }
        return activeSchedules.contains { $0.applies(to: weekday) && $0.contains(time) }
    }

    /// Applies `change` to the schedule with `id`, if it still exists.
    mutating func updateSchedule(_ id: ChimeSchedule.ID, _ change: (inout ChimeSchedule) -> Void) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }
        change(&schedules[index])
    }

    /// The Today section: active schedules for `date`'s weekday, by start time.
    func todaysSchedules(at date: Date, calendar: Calendar) -> [ChimeSchedule] {
        let weekday = Weekday(of: date, calendar: calendar)
        return activeSchedules.filter { $0.applies(to: weekday) }.sorted { $0.start < $1.start }
    }
}
