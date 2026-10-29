import Foundation
import Testing
@testable import Clocktower

struct ChimeScheduleTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    /// January 2026: the 12th is a Monday, the 15th a Thursday, the 17th a Saturday.
    func date(day: Int = 15, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }

    let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    /// Infinite off, with the given schedules.
    func scheduled(_ schedules: ChimeSchedule...) -> ChimeSettings {
        ChimeSettings(isInfinite: false, schedules: schedules)
    }

    // MARK: Data

    @Test func defaults() {
        let settings = ChimeSettings()
        #expect(settings.isInfinite)
        #expect(settings.schedules.isEmpty)
    }

    @Test func decodesSettingsSavedBeforeSchedules() throws {
        let json = #"{"isEnabled":true,"interval":30,"style":"sentence","clock":"twentyFourHour","isTimeSensitive":true}"#
        let settings = try JSONDecoder().decode(ChimeSettings.self, from: Data(json.utf8))
        #expect(settings == ChimeSettings(interval: .m30, style: .sentence, clock: .twentyFourHour, isTimeSensitive: true))
    }

    @Test func schedulesRoundTrip() throws {
        var schedule = ChimeSchedule(start: TimeOfDay(hour: 10), end: .lastMinute, weekdays: [.saturday, .sunday])
        schedule.skipToday(true, at: date(14), calendar: calendar)
        let settings = ChimeSettings(isInfinite: false, schedules: [schedule, ChimeSchedule(isEnabled: false)])

        let decoded = try JSONDecoder().decode(ChimeSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }

    // MARK: Windows

    @Test func windowIncludesStartAndExplicitEnd() {
        let schedule = ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 17))
        #expect(!schedule.contains(TimeOfDay(hour: 8, minute: 59)))
        #expect(schedule.contains(TimeOfDay(hour: 9)))
        #expect(schedule.contains(TimeOfDay(hour: 17)))
        #expect(!schedule.contains(TimeOfDay(hour: 17, minute: 1)))
    }

    @Test func decodesSchedulesSavedWithoutEndOrDays() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","isEnabled":true,"start":{"hour":10,"minute":0},"weekdays":[]}"#
        let schedule = try JSONDecoder().decode(ChimeSchedule.self, from: Data(json.utf8))
        #expect(schedule.start == TimeOfDay(hour: 10))
        #expect(schedule.end == .lastMinute)
        #expect(schedule.weekdays == Set(Weekday.allCases))
    }

    @Test func newSchedulesApplyEveryDay() {
        #expect(Weekday.allCases.allSatisfy(ChimeSchedule().applies(to:)))

        let weekend = ChimeSchedule(weekdays: [.saturday, .sunday])
        #expect(weekend.applies(to: .sunday))
        #expect(!weekend.applies(to: .monday))
    }

    @Test func weekdayMatchesCalendar() {
        #expect(Weekday(of: date(day: 12, 9), calendar: calendar) == .monday)
        #expect(Weekday(of: date(day: 17, 9), calendar: calendar) == .saturday)
    }

    @Test func endsAfterItsEndTime() {
        let schedule = ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 17))
        #expect(!schedule.hasEnded(at: date(17, 0), calendar: calendar))
        #expect(schedule.hasEnded(at: date(17, 1), calendar: calendar))
    }

    @Test func skippingTodayLastsUntilMidnight() {
        var schedule = ChimeSchedule()
        schedule.skipToday(true, at: date(14, 10), calendar: calendar)
        #expect(schedule.skippedUntil == date(day: 16, 0))
        #expect(schedule.isSkipped(at: date(23, 59)))
        #expect(!schedule.isSkipped(at: date(day: 16, 0)))

        schedule.skipToday(false, at: date(14, 20), calendar: calendar)
        #expect(schedule.skippedUntil == nil)
        #expect(!schedule.isSkipped(at: date(14, 30)))
    }

    // MARK: Which chimes fire

    @Test func masterOffNeverChimes() {
        var settings = scheduled(ChimeSchedule())
        settings.isEnabled = false
        #expect(!settings.chimes(at: date(10), calendar: calendar))

        settings.isInfinite = true
        #expect(!settings.chimes(at: date(10), calendar: calendar))
    }

    @Test func infiniteIgnoresSchedules() {
        var settings = scheduled(ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 10)))
        settings.isInfinite = true
        settings.schedules[0].skipToday(true, at: date(8), calendar: calendar)
        #expect(settings.chimes(at: date(3), calendar: calendar))
        #expect(settings.chimes(at: date(9, 30), calendar: calendar))
    }

    @Test func schedulesDecideWhenInfiniteIsOff() {
        let settings = scheduled(
            ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 17), weekdays: weekdays),
            ChimeSchedule(start: TimeOfDay(hour: 10), end: .lastMinute, weekdays: [.saturday, .sunday])
        )
        #expect(settings.chimes(at: date(9), calendar: calendar))
        #expect(settings.chimes(at: date(17), calendar: calendar))
        #expect(!settings.chimes(at: date(17, 30), calendar: calendar))
        #expect(!settings.chimes(at: date(day: 17, 9), calendar: calendar))
        #expect(settings.chimes(at: date(day: 17, 23, 30), calendar: calendar))
    }

    @Test func noActiveSchedulesNeverChimes() {
        #expect(!scheduled().chimes(at: date(10), calendar: calendar))

        let settings = scheduled(ChimeSchedule(isEnabled: false))
        #expect(!settings.chimes(at: date(10), calendar: calendar))
        #expect(settings.activeSchedules.isEmpty)
    }

    @Test func skippedScheduleResumesTomorrow() {
        var settings = scheduled(ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 17)))
        settings.schedules[0].skipToday(true, at: date(14, 10), calendar: calendar)

        #expect(!settings.chimes(at: date(14, 20), calendar: calendar))
        #expect(settings.chimes(at: date(day: 16, 9), calendar: calendar))
        #expect(settings.chimes(on: .thursday, at: TimeOfDay(hour: 14, minute: 20)))
    }

    @Test func overlappingScheduleStillChimesWhenOneIsSkipped() {
        var settings = scheduled(
            ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 12)),
            ChimeSchedule(start: TimeOfDay(hour: 11), end: TimeOfDay(hour: 14))
        )
        settings.schedules[0].skipToday(true, at: date(8), calendar: calendar)

        #expect(!settings.chimes(at: date(10), calendar: calendar))
        #expect(settings.chimes(at: date(11, 30), calendar: calendar))
    }

    @Test func todaysSchedulesAreActiveAndSortedByStart() {
        let afternoon = ChimeSchedule(start: TimeOfDay(hour: 13), end: TimeOfDay(hour: 17), weekdays: [.thursday])
        let morning = ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 12))
        let weekend = ChimeSchedule(weekdays: [.saturday, .sunday])
        let off = ChimeSchedule(isEnabled: false)
        let settings = scheduled(afternoon, weekend, morning, off)

        #expect(settings.todaysSchedules(at: date(10), calendar: calendar) == [morning, afternoon])
    }

    // MARK: Text

    @Test func windowText() {
        let schedule = ChimeSchedule(start: TimeOfDay(hour: 9), end: TimeOfDay(hour: 17, minute: 30))
        #expect(ChimeText.window(of: schedule, clock: .twelveHour) == "9:00 AM – 5:30 PM")
        #expect(ChimeText.window(of: schedule, clock: .twentyFourHour) == "09:00 – 17:30")
    }

    @Test func daysText() {
        #expect(ChimeText.days([]) == "No days")
        #expect(ChimeText.days(Set(Weekday.allCases)) == "Every day")
        #expect(ChimeText.days(weekdays) == "Weekdays")
        #expect(ChimeText.days([.sunday, .saturday]) == "Weekends")
        #expect(ChimeText.days([.friday, .monday, .wednesday]) == "Mon, Wed, Fri")
    }

    @Test func descriptionWithSchedules() {
        #expect(ChimeText.appDescription(for: ChimeSettings(isInfinite: false, interval: .m15, schedules: [ChimeSchedule()]))
            == "Get notifications every 15 minutes during your schedules.\nExample: 1:00 PM, 1:15 PM, 1:30 PM")
        #expect(ChimeText.appDescription(for: ChimeSettings(isInfinite: false))
            == "No chimes scheduled. Turn on Infinite or a schedule.")
        #expect(ChimeText.appDescription(for: ChimeSettings(isEnabled: false, isInfinite: false)) == "Chimes are off.")
    }
}
