import SwiftUI

// Same payload Ally's own EmergencyQRCodeView renders (see WearableSyncLogic, which
// forwards Ally's buildEmergencyPayload verbatim under the "emergencyQr" key) — one
// source of truth for what an emergency responder sees, whether they're reading it
// off the phone or the wrist. CoreImage isn't available on watchOS at all, so unlike
// the Wear OS/Linux siblings this view doesn't render the QR itself — the phone-side
// WatchConnectivityBridge renders it (it has CoreImage) and hands over a PNG under
// "emergencyQrImage" alongside the raw payload.
struct EmergencyQrView: View {
    var demoData: [String: Any]?

    @State private var image: UIImage?
    @State private var loading = true

    private var isDemo: Bool { demoData != nil }

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let image {
                VStack(spacing: 6) {
                    Text("Show this to emergency staff")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 140, height: 140)
                }
            } else {
                VStack(spacing: 8) {
                    Text(isDemo ? "QR preview isn't available in demo mode." : "Couldn't load the emergency QR.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    if !isDemo {
                        Button("Retry") { Task { await load() } }
                    }
                }
            }
        }
        .navigationTitle("ID")
        .task {
            if isDemo {
                loading = false
            } else {
                await load()
            }
        }
    }

    private func load() async {
        loading = true
        do {
            let data = try await WearableClient.fetchSync()
            if let base64 = data["emergencyQrImage"] as? String,
               let pngData = Data(base64Encoded: base64) {
                image = UIImage(data: pngData)
            } else {
                image = nil
            }
        } catch {
            image = nil
        }
        loading = false
    }
}
