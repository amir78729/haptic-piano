import SwiftUI
import HapticPianoCore

struct PianoKeyboardView: View {
    @EnvironmentObject private var piano: PianoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PLAY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Hold a key to sustain · Chords supported")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            GeometryReader { proxy in
                let keyWidth = proxy.size.width / CGFloat(PianoLayout.whiteSemitones.count)
                let blackWidth = keyWidth * 0.58
                let blackHeight = proxy.size.height * 0.62

                ZStack(alignment: .topLeading) {
                    HStack(spacing: 2) {
                        ForEach(PianoLayout.whiteSemitones, id: \.self) { semitone in
                            key(semitone: semitone, isBlack: false)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    ForEach(PianoLayout.blackSemitones, id: \.self) { semitone in
                        let precedingWhiteKeys = PianoLayout.whiteSemitones.filter { $0 < semitone }.count
                        key(semitone: semitone, isBlack: true)
                            .frame(width: blackWidth, height: blackHeight)
                            .position(x: CGFloat(precedingWhiteKeys) * keyWidth, y: blackHeight / 2)
                    }
                }
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }

    private func key(semitone: Int, isBlack: Bool) -> PianoKeyView {
        let midi = piano.midiNote(for: semitone)
        return PianoKeyView(
            title: PianoNote.name(for: semitone),
            isBlack: isBlack,
            isPressed: piano.activeNotes.contains(midi),
            onDown: { piano.pressMouseNote(midi) },
            onUp: { piano.releaseMouseNote(midi) }
        )
    }
}
