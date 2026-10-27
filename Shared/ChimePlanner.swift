import Foundation

/// A notification to schedule, independent of UserNotifications so it can be unit tested.
struct ChimeRequest: Equatable {
    let id: String
    let title: String?
    let body: String
    let dateComponents: DateComponents
    let repeats: Bool
}

/// Decides which notifications to schedule. See docs/SPEC.md → Notification scheduling.
enum ChimePlanner {
    /// iOS keeps at most 64 pending notification requests per app.
    static let maxPending = 64

    static func requests(for settings: ChimeSettings, now: Date, calendar: Calendar) -> [ChimeRequest] {
        guard settings.isEnabled else { return [] }
        let interval = settings.interval.minutes

        // Few enough slots per day (30, 60 min): one daily-repeating request per slot.
        if 24 * 60 / interval <= maxPending {
            return stride(from: 0, to: 24 * 60, by: interval).map { minuteOfDay in
                let hour = minuteOfDay / 60, minute = minuteOfDay % 60
                return ChimeRequest(
                    id: String(format: "chime-%02d%02d", hour, minute),
                    title: nil,
                    body: message(hour: hour, minute: minute, settings),
                    dateComponents: DateComponents(hour: hour, minute: minute),
                    repeats: true
                )
            }
        }

        // Too many (15, 20 min): the next 64 slots as one-shots. The last one asks the user to reopen the app.
        let dates = upcomingSlots(after: now, intervalMinutes: interval, count: maxPending, calendar: calendar)
        return dates.enumerated().map { index, date in
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let text = message(hour: components.hour!, minute: components.minute!, settings)
            let isLast = index == dates.count - 1
            return ChimeRequest(
                id: "chime-\(Int(date.timeIntervalSince1970))",
                title: isLast ? text : nil,
                body: isLast ? ChimeText.keepGoingReminder : text,
                dateComponents: components,
                repeats: false
            )
        }
    }

    /// Clock-aligned times strictly after `now`, e.g. :00, :20, :40 for a 20 minute interval.
    static func upcomingSlots(after now: Date, intervalMinutes: Int, count: Int, calendar: Calendar) -> [Date] {
        var hourStart = calendar.dateInterval(of: .hour, for: now)!.start
        var slots: [Date] = []
        while slots.count < count {
            for minute in stride(from: 0, to: 60, by: intervalMinutes) {
                let slot = hourStart.addingTimeInterval(TimeInterval(minute * 60))
                if slot > now, slots.count < count {
                    slots.append(slot)
                }
            }
            hourStart = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
        }
        return slots
    }

    private static func message(hour: Int, minute: Int, _ settings: ChimeSettings) -> String {
        ChimeText.message(hour: hour, minute: minute, style: settings.style, clock: settings.clock)
    }
}
