import SwiftUI

struct PianoView: View {
    @EnvironmentObject private var piano: PianoStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 22) {
            header
            controls
            PianoKeyboardView()
            footer
        }
        .padding(28)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            piano.startKeyboardMonitoring()
            piano.connect()
        }
        .onDisappear {
            piano.stopKeyboardMonitoring()
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { piano.releaseAll() }
        }
        .onExitCommand { piano.releaseAll() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("HAPTIC PIANO")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .tracking(1.4)
                Text("A small piano. No speakers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(piano.status == "Trackpad connected" ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(piano.status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary, in: Capsule())
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("OCTAVE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button { piano.octave = max(1, piano.octave - 1); piano.releaseAll() } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.bordered)
                    Text("\(piano.octave)")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .frame(width: 22)
                    Button { piano.octave = min(7, piano.octave + 1); piano.releaseAll() } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }
            Divider().frame(height: 42)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("MOTOR LEVEL")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(piano.volume * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $piano.volume, in: 0.15...1.0)
                    .frame(width: 190)
            }
            Spacer()
            Button(action: piano.reconnect) {
                Label("Reconnect", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var footer: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("Sound is produced by the Force Touch haptic motor. Place the Mac on a hard table for the clearest result. The trackpad is quiet and does not behave like a normal speaker.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Stop all notes", action: piano.releaseAll)
                .buttonStyle(.bordered)
        }
    }
}
