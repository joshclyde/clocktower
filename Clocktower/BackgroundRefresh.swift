import BackgroundTasks

/// Best-effort background refresh that refills the 15/20 minute notification window.
enum BackgroundRefresh {
    static let taskID = "com.joshclyde.clocktower.refresh"

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = .now.addingTimeInterval(4 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
