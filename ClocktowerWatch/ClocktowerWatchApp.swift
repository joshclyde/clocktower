import SwiftUI

@main
struct ClocktowerWatchApp: App {
    @State private var controller = WatchController()

    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environment(controller)
        }
    }
}
