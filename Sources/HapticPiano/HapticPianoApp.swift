import SwiftUI

@main
struct HapticPianoApp: App {
    @StateObject private var piano = PianoStore()
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                PianoView()
                    .tabItem { Label("Piano", systemImage: "pianokeys") }
                    .tag(0)
                MicrotonalView()
                    .tabItem { Label("Microtonal", systemImage: "waveform.path") }
                    .tag(1)
            }
            .environmentObject(piano)
            .frame(minWidth: 760, minHeight: 620)
            .onChange(of: selectedTab) { _ in piano.releaseAll() }
        }
        .windowStyle(.titleBar)
    }
}
