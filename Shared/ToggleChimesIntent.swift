#if os(iOS)
import AppIntents

/// Backs the iOS widget toggle. Runs in the widget extension; the app syncs the watch on its next refresh.
struct ToggleChimesIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Turn Chimes On or Off"

    @Parameter(title: "Chimes On")
    var value: Bool

    init() {}

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        var settings = SettingsStore.load()
        settings.isEnabled = value
        SettingsStore.save(settings)
        ChimeScheduler.reschedule(settings)
        return .result()
    }
}
#endif
