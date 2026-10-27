import SwiftUI
import UserNotifications

/// iPhone app state. Every change is saved and rescheduled.
@MainActor @Observable
final class ChimeController {
    private(set) var settings = SettingsStore.load()
    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    func binding<Value>(_ keyPath: WritableKeyPath<ChimeSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { value in self.update { $0[keyPath: keyPath] = value } }
        )
    }

    func update(_ change: (inout ChimeSettings) -> Void) {
        var updated = settings
        change(&updated)
        apply(updated)
    }

    /// Called when the app becomes active: picks up widget changes, asks for notification
    /// permission on first launch, and refills the notification window.
    func refresh() async {
        settings = SettingsStore.load()

        let center = UNUserNotificationCenter.current()
        if await center.notificationSettings().authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        authorization = await center.notificationSettings().authorizationStatus

        ChimeScheduler.reschedule(settings)
    }

    private func apply(_ settings: ChimeSettings) {
        self.settings = settings
        SettingsStore.save(settings)
        ChimeScheduler.reschedule(settings)
    }
}
