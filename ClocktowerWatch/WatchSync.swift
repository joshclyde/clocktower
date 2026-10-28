import WatchConnectivity

/// Watch side of settings sync: receives the iPhone's settings and sends changes made on the watch.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    /// Called on the main queue with the iPhone's latest settings.
    var onReceive: ((ChimeSettings) -> Void)?

    func activate() {
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends immediately when the iPhone is reachable, otherwise queues for delivery.
    func send(_ settings: ChimeSettings) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let payload = settings.payload
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    private func receive(_ payload: [String: Any]) {
        guard let settings = ChimeSettings(payload: payload) else { return }
        DispatchQueue.main.async { self.onReceive?(settings) }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        receive(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }
}
