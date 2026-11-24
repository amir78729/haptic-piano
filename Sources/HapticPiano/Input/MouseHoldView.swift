import AppKit
import SwiftUI

struct MouseHoldView: NSViewRepresentable {
    let onDown: () -> Void
    let onUp: () -> Void

    func makeNSView(context: Context) -> HoldNSView {
        let view = HoldNSView()
        view.onDown = onDown
        view.onUp = onUp
        return view
    }

    func updateNSView(_ nsView: HoldNSView, context: Context) {
        nsView.onDown = onDown
        nsView.onUp = onUp
    }

    static func dismantleNSView(_ nsView: HoldNSView, coordinator: ()) {
        nsView.finishPress()
    }
}

final class HoldNSView: NSView {
    var onDown: (() -> Void)?
    var onUp: (() -> Void)?
    private var isDown = false

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard !isDown else { return }
        isDown = true
        onDown?()
    }

    override func mouseUp(with event: NSEvent) {
        finishPress()
    }

    func finishPress() {
        guard isDown else { return }
        isDown = false
        onUp?()
    }
}
