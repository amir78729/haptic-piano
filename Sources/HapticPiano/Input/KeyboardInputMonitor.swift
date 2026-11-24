import AppKit
import HapticPianoCore

final class KeyboardInputMonitor {
    private let onKeyDown: (UInt16, Int) -> Void
    private let onKeyUp: (UInt16) -> Void
    private var monitor: Any?

    init(onKeyDown: @escaping (UInt16, Int) -> Void, onKeyUp: @escaping (UInt16) -> Void) {
        self.onKeyDown = onKeyDown
        self.onKeyUp = onKeyUp
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, let semitone = PianoLayout.semitoneByKeyCode[event.keyCode] else { return event }
            if event.type == .keyUp {
                self.onKeyUp(event.keyCode)
                return nil
            }

            let commandModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .function]
            guard event.modifierFlags.intersection(commandModifiers).isEmpty else { return event }
            self.onKeyDown(event.keyCode, semitone)
            return nil
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
