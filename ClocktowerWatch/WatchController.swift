import SwiftUI

/// Watch app state. Mirrors the iPhone's settings; local changes are saved (for the complication)
/// and sent to the iPhone, which reschedules and pushes the result back.
@MainActor @Observable
final class WatchController {
    private(set) var settings = SettingsStore.load()

    init() {
        WatchSync.shared.onReceive = { [weak self] settings in
            Task { @MainActor in self?.receive(settings) }
        }
        WatchSync.shared.activate()
    }

    func binding<Value>(_ keyPath: WritableKeyPath<ChimeSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { value in self.update { $0[keyPath: keyPath] = value } }
        )
    }

    func update(_ change: (inout ChimeSettings) -> Void) {
        var updated = settings
        change(&updated)
        settings = updated
        SettingsStore.save(updated)
        WatchSync.shared.send(updated)
    }

    private func receive(_ settings: ChimeSettings) {
        guard settings != self.settings else { return }
        self.settings = settings
        SettingsStore.save(settings)
    }
}
