import Foundation
import Testing
@testable import Clocktower

struct ChimeTextTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    func description(_ settings: ChimeSettings, now hour: Int, _ minute: Int) -> String {
        let now = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: hour, minute: minute))!
        return ChimeText.appDescription(for: settings, now: now, calendar: calendar)
    }

    @Test func twelveHourIncludesAMPM() {
        #expect(ChimeText.time(hour: 13, minute: 20, clock: .twelveHour) == "1:20 PM")
        #expect(ChimeText.time(hour: 1, minute: 5, clock: .twelveHour) == "1:05 AM")
        #expect(ChimeText.time(hour: 0, minute: 0, clock: .twelveHour) == "12:00 AM")
        #expect(ChimeText.time(hour: 12, minute: 45, clock: .twelveHour) == "12:45 PM")
    }

    @Test func twentyFourHour() {
        #expect(ChimeText.time(hour: 13, minute: 20, clock: .twentyFourHour) == "13:20")
        #expect(ChimeText.time(hour: 9, minute: 5, clock: .twentyFourHour) == "09:05")
        #expect(ChimeText.time(hour: 0, minute: 0, clock: .twentyFourHour) == "00:00")
    }

    @Test func messageStyles() {
        #expect(ChimeText.message(hour: 13, minute: 20, style: .timeOnly, clock: .twelveHour) == "1:20 PM")
        #expect(ChimeText.message(hour: 13, minute: 20, style: .sentence, clock: .twelveHour) == "The time is 1:20 PM")
        #expect(ChimeText.message(hour: 13, minute: 20, style: .sentence, clock: .twentyFourHour) == "The time is 13:20")
    }

    @Test func descriptionListsNextChimes() {
        #expect(description(ChimeSettings(), now: 13, 7)
            == "Clocktower sends you a notification with the time every 20 minutes, at :00, :20, and :40. Next: 1:20 PM, 1:40 PM, and 2:00 PM.")
        #expect(description(ChimeSettings(interval: .m60, clock: .twentyFourHour), now: 23, 30)
            == "Clocktower sends you a notification with the time every hour, on the hour. Next: 00:00, 01:00, and 02:00.")
    }

    @Test func descriptionShortensLongMinuteLists() {
        #expect(description(ChimeSettings(interval: .m30), now: 13, 0).contains("every 30 minutes, at :00 and :30."))
        #expect(description(ChimeSettings(interval: .m15), now: 13, 0).contains("every 15 minutes, at :00, :15, :30, and :45."))
        #expect(description(ChimeSettings(interval: .m5), now: 13, 0).contains("every 5 minutes, at :00, :05, :10, and so on."))
    }

    @Test func descriptionWhenOff() {
        #expect(description(ChimeSettings(isEnabled: false), now: 13, 7) == "Chimes are off.")
    }
}
