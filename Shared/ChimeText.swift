import Foundation

enum ChimeText {
    static let keepGoingReminder = "Open Clocktower to keep chimes going"

    /// "1:20 PM" (12-hour) or "13:20" (24-hour).
    static func time(hour: Int, minute: Int, clock: ClockFormat) -> String {
        switch clock {
        case .twelveHour:
            let h = hour % 12 == 0 ? 12 : hour % 12
            return String(format: "%d:%02d %@", h, minute, hour < 12 ? "AM" : "PM")
        case .twentyFourHour:
            return String(format: "%02d:%02d", hour, minute)
        }
    }

    static func time(_ time: TimeOfDay, clock: ClockFormat) -> String {
        self.time(hour: time.hour, minute: time.minute, clock: clock)
    }

    static func message(hour: Int, minute: Int, style: MessageStyle, clock: ClockFormat) -> String {
        let time = time(hour: hour, minute: minute, clock: clock)
        switch style {
        case .timeOnly: return time
        case .sentence: return "The time is \(time)"
        }
    }

    /// Example message shown in the settings UI.
    static func sample(style: MessageStyle, clock: ClockFormat) -> String {
        message(hour: 13, minute: 20, style: style, clock: clock)
    }

    /// Shown under the Chimes toggle, e.g. "Get notifications every 5 minutes.\nExample: 1:00 PM, 1:05 PM, 1:10 PM".
    static func appDescription(for settings: ChimeSettings) -> String {
        guard settings.isEnabled else { return "Chimes are off." }
        guard settings.isInfinite || !settings.activeSchedules.isEmpty else {
            return "No chimes scheduled. Choose All Day or turn on a schedule."
        }
        let minutes = settings.interval.minutes
        let every = minutes == 60 ? "every hour" : "every \(minutes) minutes"
        let during = settings.isInfinite ? ", all day" : " during your schedules"
        let example = (0..<3).map { index in
            let minuteOfDay = 13 * 60 + index * minutes
            return time(hour: minuteOfDay / 60, minute: minuteOfDay % 60, clock: settings.clock)
        }
        return "Get notifications \(every)\(during).\nExample: \(example.joined(separator: ", "))"
    }

    /// "9:00 AM – 5:00 PM"
    static func window(of schedule: ChimeSchedule, clock: ClockFormat) -> String {
        "\(time(schedule.start, clock: clock)) – \(time(schedule.end, clock: clock))"
    }

    /// "Every day", "Weekdays", "Weekends", "No days", or e.g. "Mon, Wed, Fri".
    static func days(_ weekdays: Set<Weekday>) -> String {
        let weekend: Set<Weekday> = [.saturday, .sunday]
        if weekdays.isEmpty { return "No days" }
        if weekdays.count == Weekday.allCases.count { return "Every day" }
        if weekdays == Set(Weekday.allCases).subtracting(weekend) { return "Weekdays" }
        if weekdays == weekend { return "Weekends" }
        return weekdays.sorted().map(\.shortLabel).joined(separator: ", ")
    }
}
