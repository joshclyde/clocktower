import Testing
@testable import Clocktower

struct ChimeTextTests {
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

    @Test func descriptionGivesExampleTimes() {
        #expect(ChimeText.appDescription(for: ChimeSettings(interval: .m5))
            == "Get notifications every 5 minutes, all day.\nExample: 1:00 PM, 1:05 PM, 1:10 PM")
        #expect(ChimeText.appDescription(for: ChimeSettings(interval: .m30, clock: .twentyFourHour))
            == "Get notifications every 30 minutes, all day.\nExample: 13:00, 13:30, 14:00")
        #expect(ChimeText.appDescription(for: ChimeSettings(interval: .m60))
            == "Get notifications every hour, all day.\nExample: 1:00 PM, 2:00 PM, 3:00 PM")
    }

    @Test func descriptionWhenOff() {
        #expect(ChimeText.appDescription(for: ChimeSettings(isEnabled: false)) == "Chimes are off.")
    }
}
