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
        #expect(ChimeSettings() == ChimeSettings(isEnabled: true, interval: .m20, style: .timeOnly, clock: .twelveHour))
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

    @Test(arguments: [ChimeInterval.m15, .m20])
    func shortIntervalsFillRollingWindow(interval: ChimeInterval) {
        let now = date(13, 7)
        let result = requests(ChimeSettings(interval: interval), now: now)

        #expect(result.count == ChimePlanner.maxPending)
        #expect(result.allSatisfy { !$0.repeats })
        #expect(Set(result.map(\.id)).count == result.count)

        let first = calendar.date(from: result.first!.dateComponents)!
        #expect(first == date(13, interval == .m15 ? 15 : 20))

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
}
