import SwiftUI
import UserNotifications

/// iPhone app state. Every change is saved and rescheduled.
@MainActor @Observable
final class ChimeController {
    private(set) var settings = SettingsStore.load()
    /// Whether the user allowed notifications for this app. `SettingsView` shows a banner when denied.
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
        // First launch only: shows the system "Allow Notifications?" prompt. iOS allows asking once.
        if await center.notificationSettings().authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        // The user's answer, or whatever they later set in Settings → Notifications.
        authorization = await center.notificationSettings().authorizationStatus

        ChimeScheduler.reschedule(settings)
    }

    private func apply(_ settings: ChimeSettings) {
        self.settings = settings
        SettingsStore.save(settings)
        ChimeScheduler.reschedule(settings)
    }
}
