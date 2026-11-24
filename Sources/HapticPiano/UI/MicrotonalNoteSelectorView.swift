import SwiftUI
import HapticPianoCore

struct MicrotonalNoteSelectorView: View {
    @EnvironmentObject private var piano: PianoStore

    var body: some View {
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    private func key(semitone: Int, isBlack: Bool) -> PianoKeyView {
        PianoKeyView(
            title: PianoNote.name(for: semitone),
            isBlack: isBlack,
            isPressed: piano.microtonalSemitone == semitone,
            onDown: { piano.selectMicrotonalNote(semitone) },
            onUp: {}
        )
    }
}
