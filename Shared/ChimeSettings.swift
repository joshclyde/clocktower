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
    /// Deliver chimes as Time Sensitive so they come through a Focus.
    var isTimeSensitive = false
}

extension ChimeSettings {
    /// Decodes field by field so settings saved before a field existed keep their other values.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ChimeSettings()
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? defaults.isEnabled
        interval = try container.decodeIfPresent(ChimeInterval.self, forKey: .interval) ?? defaults.interval
        style = try container.decodeIfPresent(MessageStyle.self, forKey: .style) ?? defaults.style
        clock = try container.decodeIfPresent(ClockFormat.self, forKey: .clock) ?? defaults.clock
        isTimeSensitive = try container.decodeIfPresent(Bool.self, forKey: .isTimeSensitive) ?? defaults.isTimeSensitive
    }
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
