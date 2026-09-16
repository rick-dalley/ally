import SwiftUI

// Pairing asks the phone, not the wearer. WatchConnectivity handles discovery and
// connection itself once the watch and phone are paired through the OS's own
// Bluetooth flow, so there is no address to enter — and, as of this view's rewrite,
// no patient UUID either. Transcribing a v4 UUID onto a 40mm screen was never a real
// flow, just the shortest path to a working prototype.
//
// Instead: ask Ally for the names it knows and let the caregiver tap one. The UUID
// still identifies the patient on every later call, it just never reaches the screen.
// Three cases fall out of that — no patients, exactly one (pair silently, never show
// this view), or several. The demo link stays reachable in all of them, including
// when the phone can't be reached, since screenshotting shouldn't need a live phone.
struct PairingView: View {
    var onPaired: () -> Void

    @State private var patients: [WearableClient.PairablePatient] = []
    @State private var loading = true
    @State private var errorMessage: String?
    // The friendly line above is what a wearer needs; this is what whoever is holding
    // a laptop needs, and swallowing it costs an afternoon. Small and dim, so it reads
    // as a footnote rather than a second alarm.
    @State private var errorDetail: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.purple)
                Text("Pair with Ally")
                    .font(.headline)

                if loading {
                    ProgressView()
                    Text("Asking Ally...")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    if let errorDetail {
                        Text(errorDetail)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Button("Try Again", action: load)
                } else if patients.isEmpty {
                    Text("Ally doesn't have anyone set up yet. Add a person on the phone first.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    Button("Try Again", action: load)
                } else {
                    Text("Who is this watch for?")
                        .font(.caption2)
                    ForEach(patients) { patient in
                        Button(patient.name) { pair(patient) }
                    }
                }

                NavigationLink("View Demo") {
                    DueItemsView(demoData: DemoData.dueItems)
                }
                .font(.caption)
            }
            .padding()
        }
        .onAppear(perform: load)
    }

    private func load() {
        loading = true
        errorMessage = nil
        errorDetail = nil
        Task {
            do {
                let found = try await WearableClient.fetchPatients()
                await MainActor.run {
                    // One patient is the only possible answer, so don't ask the
                    // question — this is most installs.
                    if found.count == 1 {
                        pair(found[0])
                        return
                    }
                    patients = found
                    loading = false
                }
            } catch {
                await MainActor.run {
                    loading = false
                    errorMessage = "Couldn't reach Ally. Open it on your phone, then try again."
                    errorDetail = error.localizedDescription
                }
            }
        }
    }

    private func pair(_ patient: WearableClient.PairablePatient) {
        WearableClient.setPatientUuid(patient.id)
        onPaired()
    }
}
