//
//  ContentView.swift
//  Ally Watch App Watch App
//
//  Created by Richard Dalley on 2026-08-28.
//

import SwiftUI

// Same three-tab shape as the Linux and Wear OS wearable shells (due items / panic /
// emergency QR) — see WearableShell in either of those apps for the reasoning.
struct ContentView: View {
    @State private var paired = WearableClient.isPaired()

    var body: some View {
        if paired {
            NavigationStack {
                TabView {
                    DueItemsView()
                        .tabItem { Label("Due", systemImage: "checklist") }
                    PanicView()
                        .tabItem { Label("Panic", systemImage: "exclamationmark.triangle") }
                    EmergencyQrView()
                        .tabItem { Label("ID", systemImage: "qrcode") }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { paired = false }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
        } else {
            PairingView(onPaired: { paired = true })
        }
    }
}

#Preview {
    ContentView()
}
