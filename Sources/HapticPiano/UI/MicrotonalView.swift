import SwiftUI
import HapticPianoCore

struct MicrotonalView: View {
    @EnvironmentObject private var piano: PianoStore

    var body: some View {
        VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 5) {
                Text("MICROTONAL")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .tracking(1.4)
                Text("Continuous pitch and volume from the trackpad.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BASE NOTE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Text("\(PianoNote.name(for: piano.microtonalSemitone))\(piano.octave)")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                }
                Divider().frame(height: 42)
                VStack(alignment: .leading, spacing: 8) {
                    Text("PITCH OFFSET")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+.2f st", piano.microtonalPitchOffset))
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                }
                Divider().frame(height: 42)
                VStack(alignment: .leading, spacing: 8) {
                    Text("VOLUME")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Text("\(Int(piano.microtonalVolume * 100))%")
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                }
                Spacer()
                Button(action: piano.reconnect) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("Reconnect trackpad")
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SELECT BASE NOTE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Choose a note before playing")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                MicrotonalNoteSelectorView()
                    .frame(height: 145)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CONTROL SURFACE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(piano.microtonalIsPlaying ? "Playing" : "Hold to play")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(piano.microtonalIsPlaying ? Color.green : Color.secondary)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                    VStack(spacing: 7) {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 20, weight: .medium))
                        Text("Pitch: -1 octave to +1 octave")
                            .font(.system(size: 12, weight: .medium))
                        Text("Volume: down to silence, up to full")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .allowsHitTesting(false)
                    MicrotonalControlView(
                        onDown: piano.startMicrotonalNote,
                        onMove: { horizontal, vertical in
                            piano.updateMicrotonalNote(horizontalDelta: horizontal, verticalDelta: vertical)
                        },
                        onUp: piano.releaseMicrotonalNote
                    )
                }
                .frame(height: 175)
            }
            Spacer(minLength: 0)
        }
        .padding(28)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { piano.connect() }
        .onDisappear { piano.releaseMicrotonalNote() }
        .onExitCommand { piano.releaseAll() }
    }
}
