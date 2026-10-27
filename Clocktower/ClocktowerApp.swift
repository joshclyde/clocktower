import SwiftUI
import UserNotifications

@main
struct ClocktowerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate: AppDelegate
    @State private var controller = ChimeController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environment(controller)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await controller.refresh() }
            case .background: BackgroundRefresh.schedule()
            default: break
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.taskID)) {
            ChimeScheduler.reschedule(SettingsStore.load())
            BackgroundRefresh.schedule()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show chimes while the app is open too.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
