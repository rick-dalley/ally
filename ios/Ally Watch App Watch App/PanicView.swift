import SwiftUI

// Same design and same honesty as the Linux and Wear OS PanicScreens: only the
// manual button is a real trigger — the Apple Watch Simulator (and most watches used
// for this prototype) has no wired-up fall/slap detection in this app yet, so those
// two stay clearly labeled simulate buttons hitting the same endpoint a real sensor
// would.
struct PanicView: View {
    var demoData: [String: Any]?

    @State private var alerts: [String: Any] = [:]
    @State private var loading = true
    @State private var sending = false
    @State private var confirmation: String?
    // See the matching guard in DueItemsView — watchOS's TabView keeps re-running
    // every tab's .task, even off-screen ones, without this.
    @State private var hasStarted = false

    private var isDemo: Bool { demoData != nil }

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else {
                content
            }
        }
        .navigationTitle("Panic")
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            if isDemo {
                alerts = demoData ?? [:]
                loading = false
            } else {
                await load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let manualOn = alerts["manual"] as? Bool ?? false
        let fallOn = alerts["fall"] as? Bool ?? false
        let slapOn = alerts["slap"] as? Bool ?? false

        ScrollView {
            VStack(spacing: 10) {
                if manualOn {
                    Button(action: { trigger("manual", "Panic Button") }) {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill").font(.title)
                            Text("Panic Button")
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                    }
                    .tint(.red)
                    .disabled(sending)
                }
                if fallOn || slapOn {
                    Text("SIMULATE (no sensor wired up)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                if fallOn {
                    Button("Simulate Fall") { trigger("fall", "Fall Detected") }
                        .disabled(sending)
                }
                if slapOn {
                    Button("Simulate Slap") { trigger("slap", "Slap Detected") }
                        .disabled(sending)
                }
                if !manualOn && !fallOn && !slapOn {
                    Text("No alerts armed — enable one in Ally's Wearable Settings.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let confirmation {
                    Text(confirmation).font(.caption2).multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }

    private func load() async {
        do {
            let data = try await WearableClient.fetchSync()
            alerts = data["alerts"] as? [String: Any] ?? [:]
        } catch {
            // Leave alerts empty — content view shows the "no alerts armed" state.
        }
        loading = false
    }

    private func trigger(_ trigger: String, _ label: String) {
        guard !sending else { return }
        sending = true
        confirmation = nil
        if isDemo {
            confirmation = "\(label) sent (demo)."
            sending = false
            return
        }
        Task {
            do {
                let notified = try await WearableClient.panic(trigger: trigger)
                confirmation = notified > 0 ? "\(label) sent to \(notified) contact\(notified == 1 ? "" : "s")." : "\(label) sent — no emergency contacts configured yet."
            } catch {
                confirmation = "Couldn't reach Ally."
            }
            sending = false
        }
    }
}
