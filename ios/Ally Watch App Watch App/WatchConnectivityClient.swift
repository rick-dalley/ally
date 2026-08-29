import Foundation
import WatchConnectivity

// Low-level session wrapper — activates WCSession once and exposes a plain
// async/await request. WCSession.sendMessage already has real request/response
// semantics (unlike the Wearable Data Layer API's one-way messaging on the Android
// side), so there's no need for the manual response-path matching that side needed.
class WatchConnectivityClient: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityClient()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    #if !os(watchOS)
    // watchOS only requires activationDidCompleteWith above — these two are marked
    // unavailable there and won't even compile. But Flutter's iOS Simulator build
    // compiles this watch target against the iOS SDK too (it forces
    // -sdk iphonesimulator across the whole embedded-watch dependency graph), and
    // iOS's WCSessionDelegate requires them. Harmless no-ops when they do apply —
    // matches WatchConnectivityBridge.swift on the phone side.
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif

    func send(method: String, arguments: String? = nil) async throws -> String {
        guard WCSession.isSupported() else {
            throw WatchConnectivityError.notSupported
        }
        // Session activation is async, and the very first call here (e.g. the
        // app's initial due-items fetch) can land in the brief window before
        // WCSession finishes activating and reports reachable — give it a moment
        // to settle rather than failing on what's usually just a startup race.
        var waited = 0
        while !WCSession.default.isReachable && waited < 20 {
            try await Task.sleep(nanoseconds: 100_000_000)
            waited += 1
        }
        guard WCSession.default.isReachable else {
            throw WatchConnectivityError.notReachable
        }
        return try await withCheckedThrowingContinuation { continuation in
            var message: [String: Any] = ["method": method]
            if let arguments {
                message["arguments"] = arguments
            }
            WCSession.default.sendMessage(
                message,
                replyHandler: { reply in
                    if let payload = reply["payload"] as? String {
                        continuation.resume(returning: payload)
                    } else {
                        let errorMessage = reply["error"] as? String ?? "Unknown error from Ally"
                        continuation.resume(throwing: WatchConnectivityError.remote(errorMessage))
                    }
                },
                errorHandler: { error in
                    continuation.resume(throwing: error)
                }
            )
        }
    }
}

enum WatchConnectivityError: LocalizedError {
    case notSupported
    case notReachable
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .notSupported: return "Watch connectivity isn't supported on this device."
        case .notReachable: return "Ally isn't reachable — make sure it's open on your phone."
        case .remote(let message): return message
        }
    }
}
