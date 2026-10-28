import WatchConnectivity

/// iPhone side of settings sync: pushes settings to the watch and receives changes made on the watch.
final class PhoneSync: NSObject, WCSessionDelegate {
    static let shared = PhoneSync()

    /// Called on the main queue with settings changed on the watch.
    var onReceive: ((ChimeSettings) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func push(_ settings: ChimeSettings) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isWatchAppInstalled else { return }
        try? session.updateApplicationContext(settings.payload)
    }

    private func receive(_ payload: [String: Any]) {
        guard let settings = ChimeSettings(payload: payload) else { return }
        DispatchQueue.main.async { self.onReceive?(settings) }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        push(SettingsStore.load())
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receive(userInfo)
    }
}
