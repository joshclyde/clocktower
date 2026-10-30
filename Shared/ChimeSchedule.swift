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

/// A window of the day when chimes fire while chimes are set to Schedule. See docs/SPEC.md → Schedules.
struct ChimeSchedule: Codable, Equatable, Identifiable {
    var id = UUID()
    var isEnabled = true
    var start = TimeOfDay(hour: 9)
    /// The last chime time; a chime at the end time fires. After `start` in saved schedules.
    var end = TimeOfDay(hour: 17)
    /// Starts with every day; saved schedules have at least one.
    var weekdays = Set(Weekday.allCases)
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
    }

    func applies(to weekday: Weekday) -> Bool {
        weekdays.contains(weekday)
    }

    /// Whether `time` is inside the window. Both the start and the end are included.
    func contains(_ time: TimeOfDay) -> Bool {
        start <= time && time <= end
    }

    /// Whether today's window has passed.
    func hasEnded(at date: Date, calendar: Calendar) -> Bool {
        TimeOfDay(of: date, calendar: calendar) > end
    }

    var endsAfterStart: Bool { end > start }

    /// Whether the editor can save it: the end is after the start, and at least one day is selected.
    var isValid: Bool { endsAfterStart && !weekdays.isEmpty }
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
        if isSnoozed(at: date) { return false }
        let weekday = Weekday(of: date, calendar: calendar)
        let time = TimeOfDay(of: date, calendar: calendar)
        return activeSchedules.contains { $0.applies(to: weekday) && $0.contains(time) }
    }

    /// Whether a chime at `time` on `weekday` fires every week, ignoring a snooze.
    func chimes(on weekday: Weekday, at time: TimeOfDay) -> Bool {
        guard isEnabled else { return false }
        if isInfinite { return true }
        return activeSchedules.contains { $0.applies(to: weekday) && $0.contains(time) }
    }

    func isSnoozed(at date: Date) -> Bool {
        snoozedUntil.map { date < $0 } ?? false
    }

    /// Snoozes every schedule for the rest of `date`'s day, or ends the snooze.
    mutating func snoozeToday(_ snooze: Bool, at date: Date, calendar: Calendar) {
        snoozedUntil = snooze ? calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) : nil
    }

    /// Applies `change` to the schedule with `id`, if it still exists.
    mutating func updateSchedule(_ id: ChimeSchedule.ID, _ change: (inout ChimeSchedule) -> Void) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }
        change(&schedules[index])
    }

    /// The Today rows: active schedules for `date`'s weekday, by start time.
    func todaysSchedules(at date: Date, calendar: Calendar) -> [ChimeSchedule] {
        let weekday = Weekday(of: date, calendar: calendar)
        return activeSchedules.filter { $0.applies(to: weekday) }.sorted { $0.start < $1.start }
    }
}
