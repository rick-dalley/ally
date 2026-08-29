import CoreImage.CIFilterBuiltins
import Flutter
import UIKit
import WatchConnectivity

// The phone-side native half of the Apple Watch transport. WCSession's
// sendMessage/replyHandler already has real request/response semantics, so this is a
// thin relay: forward whatever the watch asks for into Dart via a MethodChannel
// (where WearableSyncLogic actually answers it — see watch_connectivity_bridge.dart),
// and hand the result straight back to the watch as the reply. No business logic
// lives here on purpose, same as the Android MainActivity.kt bridge.
//
// One exception: CoreImage isn't available on watchOS at all, so the emergency QR
// can't be rendered on the watch itself. This is the one place both sides are native
// Apple platforms, so the phone renders the QR here (as a PNG) and hands the watch a
// picture instead of the raw payload it would otherwise have generated one from.
class WatchConnectivityBridge: NSObject, WCSessionDelegate {
    private var channel: FlutterMethodChannel?

    func start(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.cwicare/watch_connectivity", binaryMessenger: messenger)
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let method = message["method"] as? String else {
            replyHandler(["error": "missing method"])
            return
        }
        let arguments = message["arguments"] as? String

        DispatchQueue.main.async {
            self.channel?.invokeMethod(method, arguments: arguments) { result in
                if let payload = result as? String {
                    replyHandler(["payload": method == "sync" ? Self.withEmergencyQrImage(payload) : payload])
                } else if let error = result as? FlutterError {
                    replyHandler(["error": error.message ?? "Flutter error"])
                } else {
                    replyHandler(["error": "No response from Ally"])
                }
            }
        }
    }

    private static func withEmergencyQrImage(_ payload: String) -> String {
        guard let data = payload.data(using: .utf8),
              var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let emergencyQr = object["emergencyQr"],
              let pngData = qrPngData(for: emergencyQr) else {
            return payload
        }
        object["emergencyQrImage"] = pngData.base64EncodedString()
        guard let rebuilt = try? JSONSerialization.data(withJSONObject: object),
              let rebuiltString = String(data: rebuilt, encoding: .utf8) else {
            return payload
        }
        return rebuiltString
    }

    private static func qrPngData(for payload: Any) -> Data? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage).pngData()
    }
}
