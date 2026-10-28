import Foundation
import UserNotifications

/// Replaces all pending chimes with the ones `ChimePlanner` asks for. Only the iPhone schedules;
/// the watch gets the iPhone's notifications mirrored to it.
enum ChimeScheduler {
    static func reschedule(_ settings: ChimeSettings, now: Date = .now, calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for chime in ChimePlanner.requests(for: settings, now: now, calendar: calendar) {
            let content = UNMutableNotificationContent()
            if let title = chime.title {
                content.title = title
            }
            content.body = chime.body
            content.sound = .default
            content.interruptionLevel = settings.isTimeSensitive ? .timeSensitive : .active

            let trigger = UNCalendarNotificationTrigger(dateMatching: chime.dateComponents, repeats: chime.repeats)
            center.add(UNNotificationRequest(identifier: chime.id, content: content, trigger: trigger))
        }
    }
}
