import SwiftUI
import UserNotifications

/// iPhone app state. The iPhone is the source of truth: every change is saved, rescheduled, and pushed to the watch.
@MainActor @Observable
final class ChimeController {
    private(set) var settings = SettingsStore.load()
    /// Whether the user allowed notifications for this app. `SettingsView` shows a banner when denied.
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// Whether Siri reads Clocktower's notifications aloud (Settings → Notifications → Announce Notifications).
    private(set) var announcement: UNNotificationSetting = .notSupported

    init() {
        PhoneSync.shared.onReceive = { [weak self] settings in
            Task { @MainActor in self?.apply(settings) }
        }
        PhoneSync.shared.activate()
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
        apply(updated)
    }

    /// Called when the app becomes active: picks up widget changes, clears past chimes, asks for
    /// notification permission on first launch, refills the notification window, and syncs the watch.
    func refresh() async {
        settings = SettingsStore.load()

        let center = UNUserNotificationCenter.current()
        // Past chimes are stale once the app is open. The watch mirrors these, so they should clear there too.
        center.removeAllDeliveredNotifications()
        // First launch only: shows the system "Allow Notifications?" prompt. iOS allows asking once.
        if await center.notificationSettings().authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        // The user's answer, or whatever they later set in Settings → Notifications.
        let notificationSettings = await center.notificationSettings()
        authorization = notificationSettings.authorizationStatus
        announcement = notificationSettings.announcementSetting

        ChimeScheduler.reschedule(settings)
        PhoneSync.shared.push(settings)
    }

    private func apply(_ settings: ChimeSettings) {
        self.settings = settings
        SettingsStore.save(settings)
        ChimeScheduler.reschedule(settings)
        PhoneSync.shared.push(settings)
    }
}
