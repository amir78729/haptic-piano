import SwiftUI

struct PianoKeyView: View {
    let title: String
    let isBlack: Bool
    let isPressed: Bool
    let onDown: () -> Void
    let onUp: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: isBlack ? 6 : 7)
                .fill(fillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: isBlack ? 6 : 7)
                        .stroke(isBlack ? Color.black.opacity(0.55) : Color.black.opacity(0.17), lineWidth: 1)
                }
                .shadow(color: .black.opacity(isBlack ? 0.28 : 0.08), radius: isBlack ? 5 : 2, y: isBlack ? 4 : 2)

            Text(title)
                .font(.system(size: isBlack ? 9 : 11, weight: .medium))
                .foregroundStyle(isBlack ? Color.white.opacity(0.76) : Color.black.opacity(0.52))
                .padding(.bottom, 12)

            MouseHoldView(onDown: onDown, onUp: onUp)
                .background(Color.clear)
        }
        .scaleEffect(isPressed ? 0.985 : 1)
        .animation(.easeOut(duration: 0.06), value: isPressed)
    }

    private var fillColor: Color {
        isBlack
            ? (isPressed ? Color(white: 0.25) : Color(white: 0.10))
            : (isPressed ? Color(red: 0.80, green: 0.86, blue: 0.92) : Color(white: 0.97))
    }
}
