import SwiftUI

// No IP address needed — same reasoning as the Wear OS pairing screen. WatchConnectivity
// handles device discovery/connection itself once the watch and phone are paired
// through the OS's own Bluetooth pairing. All this needs is which patient this watch
// belongs to.
struct PairingView: View {
    var onPaired: () -> Void

    @State private var patientUuid: String = WearableClient.getPatientUuid() ?? ""
    @State private var testing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.purple)
                Text("Pair with Ally")
                    .font(.headline)
                TextField("Patient UUID", text: $patientUuid)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(.secondary))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: connect) {
                    if testing {
                        ProgressView()
                    } else {
                        Text("Connect")
                    }
                }
                .disabled(testing || patientUuid.trimmingCharacters(in: .whitespaces).isEmpty)

                NavigationLink("View Demo") {
                    DueItemsView(demoData: DemoData.dueItems)
                }
                .font(.caption)
            }
            .padding()
        }
    }

    private func connect() {
        let trimmed = patientUuid.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        testing = true
        errorMessage = nil
        WearableClient.setPatientUuid(trimmed)
        Task {
            do {
                _ = try await WearableClient.fetchSync()
                await MainActor.run {
                    testing = false
                    onPaired()
                }
            } catch {
                await MainActor.run {
                    testing = false
                    errorMessage = "Couldn't reach Ally. Make sure it's open on your phone."
                }
            }
        }
    }
}
