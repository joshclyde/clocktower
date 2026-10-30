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
    /// How far ahead one-shot chimes look for slots that fire. Covers a full week after a skipped day.
    static let oneShotHorizonDays = 14

    static func requests(for settings: ChimeSettings, now: Date, calendar: Calendar) -> [ChimeRequest] {
        guard settings.isEnabled else { return [] }
        let interval = settings.interval.minutes

        // Few enough slots per week: repeating requests, which never run out. A time of day that
        // chimes every day is one daily request; otherwise one weekly request per weekday it chimes.
        let repeating = repeatingRequests(for: settings)
        if repeating.count <= maxPending, !skipChangesToday(settings, now: now, calendar: calendar) {
            return repeating
        }

        // Too many, or a schedule is turned off for the rest of today (a repeating request can't skip
        // one day): the next 64 chimes as one-shots. The last one asks the user to reopen the app.
        let dates = upcomingSlots(
            after: now,
            before: calendar.date(byAdding: .day, value: oneShotHorizonDays, to: now)!,
            intervalMinutes: interval,
            count: maxPending,
            calendar: calendar,
            where: { settings.chimes(at: $0, calendar: calendar) }
        )
        var usedIDs = Set<String>()
        return dates.enumerated().map { index, date in
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let hour = components.hour!, minute = components.minute!
            let text = message(hour: hour, minute: minute, settings)
            let isLast = index == dates.count - 1
            // Per time of day, so today's 9:00 replaces yesterday's. A time of day that comes up again
            // (schedules can spread 64 chimes over several days) gets the date added to stay unique.
            var id = timeID(hour: hour, minute: minute)
            if !usedIDs.insert(id).inserted {
                id += String(format: "-%04d%02d%02d", components.year!, components.month!, components.day!)
            }
            return ChimeRequest(
                id: id,
                title: isLast ? text : nil,
                body: isLast ? ChimeText.keepGoingReminder : text,
                dateComponents: components,
                repeats: false
            )
        }
    }

    private static func repeatingRequests(for settings: ChimeSettings) -> [ChimeRequest] {
        stride(from: 0, to: 24 * 60, by: settings.interval.minutes).flatMap { minuteOfDay -> [ChimeRequest] in
            let time = TimeOfDay(minuteOfDay: minuteOfDay)
            let body = message(hour: time.hour, minute: time.minute, settings)
            let id = timeID(hour: time.hour, minute: time.minute)
            let weekdays = Weekday.allCases.filter { settings.chimes(on: $0, at: time) }
            if weekdays.count == Weekday.allCases.count {
                return [ChimeRequest(id: id, title: nil, body: body, dateComponents: DateComponents(hour: time.hour, minute: time.minute), repeats: true)]
            }
            return weekdays.map { weekday in
                ChimeRequest(
                    id: "\(id)-\(weekday.rawValue)",
                    title: nil,
                    body: body,
                    dateComponents: DateComponents(hour: time.hour, minute: time.minute, weekday: weekday.rawValue),
                    repeats: true
                )
            }
        }
    }

    /// Whether a schedule turned off for today drops a chime that the repeating requests would still
    /// deliver before midnight. Once its window has passed it no longer matters.
    private static func skipChangesToday(_ settings: ChimeSettings, now: Date, calendar: Calendar) -> Bool {
        guard let skippedUntil = settings.schedules.compactMap(\.skippedUntil).max(), skippedUntil > now else {
            return false
        }
        let slots = upcomingSlots(after: now, before: skippedUntil, intervalMinutes: settings.interval.minutes, count: .max, calendar: calendar)
        return slots.contains { slot in
            let weekday = Weekday(of: slot, calendar: calendar), time = TimeOfDay(of: slot, calendar: calendar)
            return settings.chimes(on: weekday, at: time) && !settings.chimes(at: slot, calendar: calendar)
        }
    }

    /// Clock-aligned times strictly after `now` (and before `end`, if given) that pass `isIncluded`,
    /// e.g. :00, :20, :40 for a 20 minute interval.
    static func upcomingSlots(
        after now: Date,
        before end: Date? = nil,
        intervalMinutes: Int,
        count: Int,
        calendar: Calendar,
        where isIncluded: (Date) -> Bool = { _ in true }
    ) -> [Date] {
        var hourStart = calendar.dateInterval(of: .hour, for: now)!.start
        var slots: [Date] = []
        while slots.count < count, end.map({ hourStart < $0 }) ?? true {
            for minute in stride(from: 0, to: 60, by: intervalMinutes) {
                let slot = hourStart.addingTimeInterval(TimeInterval(minute * 60))
                if slot > now, end.map({ slot < $0 }) ?? true, slots.count < count, isIncluded(slot) {
                    slots.append(slot)
                }
            }
            hourStart = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
        }
        return slots
    }

    private static func timeID(hour: Int, minute: Int) -> String {
        String(format: "chime-%02d%02d", hour, minute)
    }

    private static func message(hour: Int, minute: Int, _ settings: ChimeSettings) -> String {
        ChimeText.message(hour: hour, minute: minute, clock: settings.clock, customMessage: settings.customMessage)
    }
}
