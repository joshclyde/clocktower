import Foundation

enum ChimeInterval: Int, Codable, CaseIterable, Identifiable {
    case m5 = 5, m10 = 10, m15 = 15, m20 = 20, m30 = 30, m60 = 60

    var id: Self { self }
    var minutes: Int { rawValue }
    var label: String { self == .m60 ? "1 hr" : "\(rawValue) min" }
}

enum ClockFormat: String, Codable, CaseIterable, Identifiable {
    case twelveHour     // "1:20 PM"
    case twentyFourHour // "13:20"

    var id: Self { self }
    var label: String { self == .twelveHour ? "12-hour" : "24-hour" }
    var shortLabel: String { self == .twelveHour ? "12h" : "24h" }
}

/// The top-level choice in the UI. Stored as `ChimeSettings.isEnabled` and `isInfinite`.
enum ChimeMode: CaseIterable, Identifiable {
    case off       // no chimes
    case on        // every interval, every day
    case schedule  // only during the schedules

    var id: Self { self }

    var label: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .schedule: return "Schedule"
        }
    }
}

/// The user's own words around the time in each chime, e.g. "Stand up" + "1:20 PM" + "and stretch".
/// Either or both can be empty; both empty chimes just the time.
struct CustomMessage: Codable, Equatable {
    var prefix = ""
    var suffix = ""
}

extension CustomMessage {
    /// Decodes field by field so messages saved before a field existed still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix) ?? ""
        suffix = try container.decodeIfPresent(String.self, forKey: .suffix) ?? ""
    }
}

/// Saved on each device and synced between the iPhone and the watch. Before adding, removing or
/// renaming a field here or in a type inside it, see docs/CONVENTIONS.md → Saved data.
struct ChimeSettings: Codable, Equatable {
    /// False for Off. See `mode`.
    var isEnabled = true
    /// While enabled: true for On (every interval, every day), false for Schedule. Keeps its
    /// original name so saved settings still load. See `mode`.
    var isInfinite = true
    var interval: ChimeInterval = .m20
    var customMessage = CustomMessage()
    var clock: ClockFormat = .twelveHour
    /// Deliver chimes as Time Sensitive so they come through a Focus.
    var isTimeSensitive = false
    var schedules: [ChimeSchedule] = []
}

extension ChimeSettings {
    /// Off, On or Schedule. Choosing Off leaves `isInfinite` as it was.
    var mode: ChimeMode {
        get { !isEnabled ? .off : isInfinite ? .on : .schedule }
        set {
            isEnabled = newValue != .off
            if newValue != .off {
                isInfinite = newValue == .on
            }
        }
    }
}

extension ChimeSettings {
    /// Decodes field by field so settings saved before a field existed keep their other values.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ChimeSettings()
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? defaults.isEnabled
        isInfinite = try container.decodeIfPresent(Bool.self, forKey: .isInfinite) ?? defaults.isInfinite
        interval = try container.decodeIfPresent(ChimeInterval.self, forKey: .interval) ?? defaults.interval
        customMessage = try container.decodeIfPresent(CustomMessage.self, forKey: .customMessage) ?? defaults.customMessage
        clock = try container.decodeIfPresent(ClockFormat.self, forKey: .clock) ?? defaults.clock
        isTimeSensitive = try container.decodeIfPresent(Bool.self, forKey: .isTimeSensitive) ?? defaults.isTimeSensitive
        schedules = try container.decodeIfPresent([ChimeSchedule].self, forKey: .schedules) ?? defaults.schedules
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
