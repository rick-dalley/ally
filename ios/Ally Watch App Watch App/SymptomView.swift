import SwiftUI

// Quick-pick symptom flags — deliberately not a full Symptoms entry (that needs a
// tap location on the body-outline diagram, which only the phone can offer, see
// BodyOutlineScreen). Tapping one just tells Ally "something's up, remind me to log
// it properly," so unlike MoodView there's no persistent "current" selection — every
// tap is its own event, and the row briefly shows a checkmark to confirm it landed.
struct SymptomView: View {
    var demoData: [String: Any]?

    @State private var options: [String] = []
    @State private var loading = true
    @State private var busyLabel: String?
    @State private var justFlagged: String?
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
        .navigationTitle("Symptoms")
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            if isDemo {
                options = (demoData?["symptomOptions"] as? [String]) ?? []
                loading = false
            } else {
                await load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Tap what you're feeling — we'll remind you to add the details later.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ForEach(options, id: \.self) { label in
                    Button(action: { flag(label) }) {
                        HStack {
                            Text(label)
                            Spacer()
                            if justFlagged == label {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(busyLabel != nil)
                }
            }
            .padding()
        }
    }

    private func load() async {
        loading = true
        if let data = try? await WearableClient.fetchSync() {
            options = (data["symptomOptions"] as? [String]) ?? []
        }
        loading = false
    }

    private func flag(_ label: String) {
        justFlagged = nil
        if isDemo {
            showConfirmation(for: label)
            return
        }
        guard busyLabel == nil else { return }
        busyLabel = label
        Task {
            _ = try? await WearableClient.flagSymptom(label: label)
            busyLabel = nil
            showConfirmation(for: label)
        }
    }

    private func showConfirmation(for label: String) {
        justFlagged = label
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if justFlagged == label { justFlagged = nil }
        }
    }
}
