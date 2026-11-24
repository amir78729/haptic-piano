import AppKit
import SwiftUI

struct MicrotonalControlView: NSViewRepresentable {
    let onDown: () -> Void
    let onMove: (CGFloat, CGFloat) -> Void
    let onUp: () -> Void

    func makeNSView(context: Context) -> MicrotonalControlNSView {
        let view = MicrotonalControlNSView()
        view.onDown = onDown
        view.onMove = onMove
        view.onUp = onUp
        return view
    }

    func updateNSView(_ nsView: MicrotonalControlNSView, context: Context) {
        nsView.onDown = onDown
        nsView.onMove = onMove
        nsView.onUp = onUp
    }

    static func dismantleNSView(_ nsView: MicrotonalControlNSView, coordinator: ()) {
        nsView.finishPress()
    }
}

final class MicrotonalControlNSView: NSView {
    var onDown: (() -> Void)?
    var onMove: ((CGFloat, CGFloat) -> Void)?
    var onUp: (() -> Void)?
    private var startLocation: NSPoint?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        startLocation = convert(event.locationInWindow, from: nil)
        onDown?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startLocation else { return }
        let location = convert(event.locationInWindow, from: nil)
        onMove?(location.x - startLocation.x, location.y - startLocation.y)
    }

    override func mouseUp(with event: NSEvent) {
        finishPress()
    }

    func finishPress() {
        guard startLocation != nil else { return }
        startLocation = nil
        onUp?()
    }
}
