import SwiftUI

@main
struct HapticPianoApp: App {
    @StateObject private var piano = PianoStore()

    var body: some Scene {
        WindowGroup {
            PianoView()
                .environmentObject(piano)
                .frame(minWidth: 760, minHeight: 520)
        }
        .windowStyle(.titleBar)
    }
}
