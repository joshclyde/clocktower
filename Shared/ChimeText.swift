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

    /// Shown under the Chimes toggle: what the app does and the next chime times for these settings.
    static func appDescription(for settings: ChimeSettings, now: Date, calendar: Calendar = .current) -> String {
        guard settings.isEnabled else { return "Chimes are off." }
        let summary = "Clocktower sends you a notification with the time \(schedule(for: settings.interval))."
        let next = ChimePlanner.upcomingSlots(after: now, intervalMinutes: settings.interval.minutes, count: 3, calendar: calendar)
            .map { date in
                let components = calendar.dateComponents([.hour, .minute], from: date)
                return time(hour: components.hour!, minute: components.minute!, clock: settings.clock)
            }
        return "\(summary) Next: \(list(next))."
    }

    /// "every 20 minutes, at :00, :20, and :40" or "every hour, on the hour".
    private static func schedule(for interval: ChimeInterval) -> String {
        if interval == .m60 { return "every hour, on the hour" }
        let marks = stride(from: 0, to: 60, by: interval.minutes).map { String(format: ":%02d", $0) }
        let shown = marks.count <= 4 ? list(marks) : marks.prefix(3).joined(separator: ", ") + ", and so on"
        return "every \(interval.minutes) minutes, at \(shown)"
    }

    /// "a and b" or "a, b, and c".
    private static func list(_ items: [String]) -> String {
        if items.count <= 2 { return items.joined(separator: " and ") }
        return items.dropLast().joined(separator: ", ") + ", and " + items.last!
    }
}
