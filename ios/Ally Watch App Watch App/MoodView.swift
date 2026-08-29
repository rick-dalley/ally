import SwiftUI

// Same due-items-style screen shape as DueItemsView/PanicView — see those files' doc
// comments for the shared conventions (hasStarted guard, demo mode). Ally's own
// Sentiment enum can't be shared with Swift, so the server sends each option's
// label + hex color (see WearableSyncLogic.moodOptions) and this picks its own SF
// Symbol per label rather than trying to transmit Material Symbols codepoints.
struct MoodView: View {
    var demoData: [String: Any]?

    @State private var currentMood: [String: Any]?
    @State private var options: [[String: Any]] = []
    @State private var loading = true
    @State private var busy = false
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
        .navigationTitle("Mood")
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            if isDemo {
                currentMood = demoData?["currentMood"] as? [String: Any]
                options = (demoData?["moodOptions"] as? [[String: Any]]) ?? []
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
                if let currentMood {
                    VStack(spacing: 4) {
                        Text("Feeling")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text((currentMood["label"] as? String) ?? "")
                            .font(.headline)
                            .foregroundStyle(colorFrom(currentMood["color"] as? String))
                    }
                    .padding(.bottom, 4)
                }
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    let index = option["index"] as? Int ?? -1
                    let isCurrent = (currentMood?["index"] as? Int) == index
                    Button(action: { setMood(index) }) {
                        HStack {
                            Circle()
                                .fill(colorFrom(option["color"] as? String))
                                .frame(width: 14, height: 14)
                            Text((option["label"] as? String) ?? "")
                            Spacer()
                            if isCurrent {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(busy || isCurrent)
                }
            }
            .padding()
        }
    }

    private func colorFrom(_ hex: String?) -> Color {
        guard let hex, hex.hasPrefix("#"), hex.count == 7,
              let value = Int(hex.dropFirst(), radix: 16) else { return .primary }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    private func load() async {
        loading = true
        do {
            let data = try await WearableClient.fetchSync()
            currentMood = data["currentMood"] as? [String: Any]
            options = (data["moodOptions"] as? [[String: Any]]) ?? []
        } catch {
            // Leave options empty — an empty list just shows nothing to pick, same
            // as DueItemsView's "nothing due" rather than a hard error screen.
        }
        loading = false
    }

    private func setMood(_ index: Int) {
        if isDemo {
            currentMood = options.first { ($0["index"] as? Int) == index }
            return
        }
        guard !busy else { return }
        busy = true
        Task {
            if let result = try? await WearableClient.setMood(index: index) {
                currentMood = result["currentMood"] as? [String: Any]
                options = (result["moodOptions"] as? [[String: Any]]) ?? options
            }
            busy = false
        }
    }
}
