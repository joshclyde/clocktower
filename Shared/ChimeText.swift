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
}
