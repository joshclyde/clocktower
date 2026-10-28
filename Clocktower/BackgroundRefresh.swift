import BackgroundTasks

/// Best-effort background refresh that refills the 5–20 minute notification window.
///
/// iOS decides when (or whether) to run it, based on app usage, battery, Low Power Mode and the
/// Background App Refresh setting. It never runs after the user force-quits the app.
enum BackgroundRefresh {
    static let taskID = "com.joshclyde.clocktower.refresh"

    /// Asks iOS for one background run. Called when the app goes to the background and after
    /// each run, so a request is always pending; a new submit replaces the previous one.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        // Lower bound only: iOS may run it later, or not at all. 60 * 60 seconds = 1 hour,
        // leaving several refill chances before a 5 min window (~5 h) runs out.
        request.earliestBeginDate = .now.addingTimeInterval(60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
