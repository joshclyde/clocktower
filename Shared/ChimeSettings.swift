import Foundation

enum ChimeInterval: Int, Codable, CaseIterable, Identifiable {
    case m15 = 15, m20 = 20, m30 = 30, m60 = 60

    var id: Self { self }
    var minutes: Int { rawValue }
    var label: String { self == .m60 ? "1 hr" : "\(rawValue) min" }
}

enum MessageStyle: String, Codable, CaseIterable, Identifiable {
    case timeOnly   // "1:20 PM"
    case sentence   // "The time is 1:20 PM"

    var id: Self { self }
}

enum ClockFormat: String, Codable, CaseIterable, Identifiable {
    case twelveHour     // "1:20 PM"
    case twentyFourHour // "13:20"

    var id: Self { self }
    var label: String { self == .twelveHour ? "12-hour" : "24-hour" }
    var shortLabel: String { self == .twelveHour ? "12h" : "24h" }
}

struct ChimeSettings: Codable, Equatable {
    var isEnabled = true
    var interval: ChimeInterval = .m20
    var style: MessageStyle = .timeOnly
    var clock: ClockFormat = .twelveHour
}

// MARK: - WatchConnectivity payload

extension ChimeSettings {
    private static let payloadKey = "settings"

    var payload: [String: Any] {
        [Self.payloadKey: (try? JSONEncoder().encode(self)) ?? Data()]
    }

    init?(payload: [String: Any]) {
        guard let data = payload[Self.payloadKey] as? Data,
              let settings = try? JSONDecoder().decode(ChimeSettings.self, from: data)
        else { return nil }
        self = settings
    }
}
