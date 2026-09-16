import SwiftUI

// The wrist variant of Ally's emergency QR — name, blood type, allergies, conditions,
// and nothing else (see EmergencyQRCodeView.buildWatchEmergencyText for why the full
// phone payload can't be used at this size). CoreImage isn't available on watchOS at
// all, so unlike the Wear OS sibling this view doesn't render the QR itself — the
// phone-side WatchConnectivityBridge renders it and hands over a PNG under
// "emergencyQrImage".
struct EmergencyQrView: View {
    var demoData: [String: Any]?

    @State private var image: UIImage?
    @State private var loading = true
    // See the matching guard in DueItemsView — watchOS's TabView keeps re-running
    // every tab's .task, even off-screen ones, without this.
    @State private var hasStarted = false

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
                    // Sized up from 140: at watch scale every point is a module the
                    // responder's camera has to resolve, and this is only ever read at
                    // arm's length in poor light. .interpolation(.none) keeps the module
                    // edges hard rather than blurring them as it scales.
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 160, height: 160)
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
            guard !hasStarted else { return }
            hasStarted = true
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
