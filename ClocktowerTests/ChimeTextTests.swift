import Testing
@testable import Clocktower

struct ChimeTextTests {
    @Test func twelveHourDropsAMPM() {
        #expect(ChimeText.time(hour: 13, minute: 20, clock: .twelveHour) == "1:20")
        #expect(ChimeText.time(hour: 1, minute: 5, clock: .twelveHour) == "1:05")
        #expect(ChimeText.time(hour: 0, minute: 0, clock: .twelveHour) == "12:00")
        #expect(ChimeText.time(hour: 12, minute: 45, clock: .twelveHour) == "12:45")
    }

    @Test func twentyFourHour() {
        #expect(ChimeText.time(hour: 13, minute: 20, clock: .twentyFourHour) == "13:20")
        #expect(ChimeText.time(hour: 9, minute: 5, clock: .twentyFourHour) == "09:05")
        #expect(ChimeText.time(hour: 0, minute: 0, clock: .twentyFourHour) == "00:00")
    }

    @Test func messageStyles() {
        #expect(ChimeText.message(hour: 13, minute: 20, style: .timeOnly, clock: .twelveHour) == "1:20")
        #expect(ChimeText.message(hour: 13, minute: 20, style: .sentence, clock: .twelveHour) == "The time is 1:20")
        #expect(ChimeText.message(hour: 13, minute: 20, style: .sentence, clock: .twentyFourHour) == "The time is 13:20")
    }
}
