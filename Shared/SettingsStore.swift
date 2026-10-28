import Foundation
import WidgetKit

/// Settings persisted in the App Group so the app and its widget/complication on the same device share them.
enum SettingsStore {
    static let appGroup = "group.com.joshclyde.clocktower"
    private static let key = "chimeSettings"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func load() -> ChimeSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(ChimeSettings.self, from: data)
        else { return ChimeSettings() }
        return settings
    }

    /// Saves and refreshes the widget/complication.
    static func save(_ settings: ChimeSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
