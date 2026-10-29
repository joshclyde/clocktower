import Foundation
import Testing
@testable import Clocktower

struct ChimePlannerTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    func date(day: Int = 10, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }

    func requests(_ settings: ChimeSettings, now: Date) -> [ChimeRequest] {
        ChimePlanner.requests(for: settings, now: now, calendar: calendar)
    }

    @Test func defaults() {
        #expect(ChimeSettings() == ChimeSettings(isEnabled: true, interval: .m20, style: .timeOnly, clock: .twelveHour, isTimeSensitive: false))
    }

    @Test func decodesSettingsSavedBeforeTimeSensitive() throws {
        let json = #"{"isEnabled":false,"interval":30,"style":"sentence","clock":"twentyFourHour"}"#
        let settings = try JSONDecoder().decode(ChimeSettings.self, from: Data(json.utf8))
        #expect(settings == ChimeSettings(isEnabled: false, interval: .m30, style: .sentence, clock: .twentyFourHour, isTimeSensitive: false))
    }

    @Test func disabledSchedulesNothing() {
        var settings = ChimeSettings()
        settings.isEnabled = false
        #expect(requests(settings, now: date(13, 7)).isEmpty)
    }

    @Test(arguments: zip([ChimeInterval.m30, .m60], [48, 24]))
    func longIntervalsRepeatDaily(interval: ChimeInterval, count: Int) {
        let result = requests(ChimeSettings(interval: interval), now: date(13, 7))

        #expect(result.count == count)
        #expect(result.allSatisfy { $0.repeats && $0.title == nil })
        #expect(Set(result.map(\.id)).count == count)
        #expect(result.first?.id == "chime-0000")
        #expect(result.first?.body == "12:00 AM")
        #expect(result.first?.dateComponents == DateComponents(hour: 0, minute: 0))
    }

    @Test(arguments: zip([ChimeInterval.m5, .m10, .m15, .m20], [10, 10, 15, 20]))
    func shortIntervalsFillRollingWindow(interval: ChimeInterval, firstMinute: Int) {
        let now = date(13, 7)
        let result = requests(ChimeSettings(interval: interval), now: now)

        #expect(result.count == ChimePlanner.maxPending)
        #expect(result.allSatisfy { !$0.repeats })
        #expect(Set(result.map(\.id)).count == result.count)
        #expect(result.first?.id == String(format: "chime-13%02d", firstMinute))

        let first = calendar.date(from: result.first!.dateComponents)!
        #expect(first == date(13, firstMinute))

        let last = calendar.date(from: result.last!.dateComponents)!
        #expect(last == first.addingTimeInterval(TimeInterval(63 * interval.minutes * 60)))
    }

    @Test func lastRollingChimeAsksToReopenApp() {
        let result = requests(ChimeSettings(interval: .m20, style: .sentence), now: date(13, 7))

        #expect(result.first?.title == nil)
        #expect(result.first?.body == "The time is 1:20 PM")
        #expect(result.dropLast().allSatisfy { $0.title == nil && $0.body != ChimeText.keepGoingReminder })
        #expect(result.last?.title?.hasPrefix("The time is ") == true)
        #expect(result.last?.body == ChimeText.keepGoingReminder)
    }

    @Test func slotsSkipTheCurrentInstant() {
        let slots = ChimePlanner.upcomingSlots(after: date(13, 20), intervalMinutes: 20, count: 3, calendar: calendar)
        #expect(slots == [date(13, 40), date(14, 0), date(14, 20)])
    }

    @Test func slotsCrossMidnight() {
        let slots = ChimePlanner.upcomingSlots(after: date(23, 50), intervalMinutes: 15, count: 2, calendar: calendar)
        #expect(slots == [date(day: 11, 0, 0), date(day: 11, 0, 15)])
    }

    // MARK: Schedules

    /// Mon–Fri 9 AM–5 PM, and Sat–Sun 10 AM until midnight. January 2026: the 15th is a Thursday.
    func weekdaysAndWeekends(_ interval: ChimeInterval) -> ChimeSettings {
        ChimeSettings(isInfinite: false, interval: interval, schedules: [
            ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 17), weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]),
            ChimeSchedule(start: TimeOfDay(hour: 10), end: nil, weekdays: [.saturday, .sunday]),
        ])
    }

    @Test func infiniteIgnoresSchedules() {
        var settings = weekdaysAndWeekends(.m60)
        settings.isInfinite = true
        let result = requests(settings, now: date(day: 15, 14, 10))
        #expect(result.count == 24)
        #expect(result.allSatisfy { $0.repeats && $0.dateComponents.weekday == nil })
    }

    @Test func schedulesRepeatDailyAndWeekly() {
        let result = requests(weekdaysAndWeekends(.m30), now: date(day: 15, 14, 10))

        // 10:00 AM–5:00 PM every day (15), 9:00 and 9:30 AM on weekdays (2 × 5), 5:30–11:30 PM on weekends (13 × 2).
        #expect(result.count == 51)
        #expect(result.allSatisfy { $0.repeats && $0.title == nil })
        #expect(Set(result.map(\.id)).count == result.count)
        #expect(result.filter { $0.dateComponents.weekday == nil }.count == 15)

        let byID = Dictionary(uniqueKeysWithValues: result.map { ($0.id, $0) })
        #expect(byID["chime-1700"]?.dateComponents == DateComponents(hour: 17, minute: 0))
        #expect(byID["chime-0900-2"]?.dateComponents == DateComponents(hour: 9, minute: 0, weekday: 2))
        #expect(byID["chime-0900-1"] == nil)
        #expect(byID["chime-2330-7"]?.body == "11:30 PM")
        #expect(byID["chime-0000"] == nil)
    }

    @Test func schedulesWithTooManySlotsUseOneShots() {
        let result = requests(weekdaysAndWeekends(.m20), now: date(day: 15, 14, 10))

        #expect(result.count == ChimePlanner.maxPending)
        #expect(result.allSatisfy { !$0.repeats })
        #expect(Set(result.map(\.id)).count == result.count)
        #expect(calendar.date(from: result.first!.dateComponents) == date(day: 15, 14, 20))
        #expect(calendar.date(from: result.last!.dateComponents) == date(day: 17, 19, 40))
        #expect(result.last?.body == ChimeText.keepGoingReminder)

        // Thursday 2:20 PM keeps the plain ID; Friday's 2:20 PM gets the date added.
        #expect(result.first?.id == "chime-1420")
        #expect(result.contains { $0.id == "chime-1420-20260116" })
        #expect(result.contains { $0.id == "chime-0900" })
    }

    @Test func scheduleSkippedTodayResumesTomorrow() {
        var settings = weekdaysAndWeekends(.m30)
        let now = date(day: 15, 14, 10)
        settings.schedules[0].skipToday(true, at: now, calendar: calendar)
        let result = requests(settings, now: now)

        #expect(result.count == ChimePlanner.maxPending)
        #expect(result.allSatisfy { !$0.repeats })
        #expect(calendar.date(from: result.first!.dateComponents) == date(day: 16, 9, 0))
        #expect(calendar.date(from: result.last!.dateComponents) == date(day: 18, 19, 0))
    }

    @Test func skipAfterTheWindowEndedKeepsRepeating() {
        var settings = weekdaysAndWeekends(.m30)
        let now = date(day: 15, 18, 0)
        settings.schedules[0].skipToday(true, at: now, calendar: calendar)
        let result = requests(settings, now: now)

        #expect(result.count == 51)
        #expect(result.allSatisfy(\.repeats))
    }

    @Test func skippedWeeklyScheduleReachesNextWeek() {
        var settings = ChimeSettings(isInfinite: false, interval: .m60, schedules: [
            ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 10), weekdays: [.monday]),
        ])
        let now = date(day: 12, 8, 0)
        settings.schedules[0].skipToday(true, at: now, calendar: calendar)
        let result = requests(settings, now: now)

        #expect(result.map { calendar.date(from: $0.dateComponents)! } == [date(day: 19, 9, 0), date(day: 19, 10, 0)])
        #expect(result.last?.body == ChimeText.keepGoingReminder)
    }

    @Test func noActiveSchedulesSchedulesNothing() {
        var settings = weekdaysAndWeekends(.m20)
        settings.isScheduleEnabled = false
        #expect(requests(settings, now: date(day: 15, 14, 10)).isEmpty)
        #expect(requests(ChimeSettings(isInfinite: false), now: date(day: 15, 14, 10)).isEmpty)
    }

    @Test func slotsStopBeforeTheEnd() {
        let slots = ChimePlanner.upcomingSlots(after: date(13, 0), before: date(14, 0), intervalMinutes: 20, count: .max, calendar: calendar)
        #expect(slots == [date(13, 20), date(13, 40)])
    }
}
