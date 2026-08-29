import SwiftUI

// Same screen and behavior as the Linux and Wear OS DueItemsScreens — see those
// files' doc comments. Only the transport differs (WatchConnectivity), which
// WearableClient hides behind the same request-shaped API.
struct DueItemsView: View {
    // Non-nil only from the "View Demo" link — renders with zero network/pairing.
    var demoData: [String: Any]?

    @State private var data: [String: Any]?
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var busy = false
    // watchOS's TabView builds every tab's body up front and keeps re-invoking
    // .task on tabs that aren't even visible, which without this guard restarts
    // the fetch (and re-flashes the spinner) roughly once a second.
    @State private var hasStarted = false

    private var isDemo: Bool { demoData != nil }

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                    Button("Retry") { Task { await refresh() } }
                }
            } else {
                content
            }
        }
        .navigationTitle("Due")
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            if isDemo {
                data = demoData
                loading = false
            } else {
                await refresh()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let medications = data?["medications"] as? [[String: Any]] ?? []
        let careOrders = data?["careOrders"] as? [[String: Any]] ?? []
        let doneMedIds = Set((data?["doneMedicationIds"] as? [String]) ?? [])
        let doneOrderIds = Set((data?["doneCareOrderIds"] as? [String]) ?? [])
        let allDone = medications.allSatisfy { doneMedIds.contains($0["id"] as? String ?? "") }
            && careOrders.allSatisfy { doneOrderIds.contains($0["id"] as? String ?? "") }

        if medications.isEmpty && careOrders.isEmpty {
            Text("Nothing due right now.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            List {
                ForEach(Array(medications.enumerated()), id: \.offset) { _, med in
                    let id = med["id"] as? String ?? ""
                    ItemRow(
                        icon: "pills.fill",
                        title: med["name"] as? String ?? "",
                        subtitle: [med["dose"] as? String, med["freq"] as? String].compactMap { $0 }.joined(separator: " — "),
                        done: doneMedIds.contains(id)
                    ) { ack(type: "medication", id: id) }
                }
                ForEach(Array(careOrders.enumerated()), id: \.offset) { _, order in
                    let id = order["id"] as? String ?? ""
                    ItemRow(
                        icon: "list.clipboard.fill",
                        title: order["label"] as? String ?? "",
                        subtitle: order["directions"] as? String ?? "",
                        done: doneOrderIds.contains(id)
                    ) { ack(type: "careOrder", id: id) }
                }
                if !allDone {
                    Button("All Taken") { ackAll() }
                        .disabled(busy)
                }
            }
        }
    }

    private func refresh() async {
        loading = true
        errorMessage = nil
        do {
            data = try await WearableClient.fetchSync()
        } catch {
            errorMessage = "Couldn't reach Ally."
        }
        loading = false
    }

    private func ack(type: String, id: String) {
        if isDemo {
            var updated = data ?? [:]
            let key = type == "medication" ? "doneMedicationIds" : "doneCareOrderIds"
            var ids = (updated[key] as? [String]) ?? []
            ids.append(id)
            updated[key] = ids
            data = updated
            return
        }
        guard !busy else { return }
        busy = true
        Task {
            if let result = try? await WearableClient.acknowledge(type: type, id: id) {
                data = result
            }
            busy = false
        }
    }

    private func ackAll() {
        if isDemo {
            var updated = data ?? [:]
            let medIds = (updated["medications"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
            let orderIds = (updated["careOrders"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
            updated["doneMedicationIds"] = medIds
            updated["doneCareOrderIds"] = orderIds
            data = updated
            return
        }
        guard !busy else { return }
        busy = true
        Task {
            if let result = try? await WearableClient.acknowledgeAll() {
                data = result
            }
            busy = false
        }
    }
}

private struct ItemRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let done: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon).foregroundStyle(done ? .green : .primary)
                VStack(alignment: .leading) {
                    Text(title).strikethrough(done).fontWeight(.semibold)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? .green : .secondary)
            }
        }
        .disabled(done)
    }
}
