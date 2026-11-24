import Combine
import Foundation
import HapticPianoCore

@MainActor
final class PianoStore: ObservableObject {
    @Published private(set) var status = "Not connected"
    @Published private(set) var activeNotes: Set<Int> = []
    @Published var volume: Double = 0.72 {
        didSet { playback.level = Float(volume) }
    }
    @Published var octave: Int = 4

    private var engine: MultitouchHapticEngine?
    private let playback = PlaybackCoordinator()
    private var keyboardMonitor: KeyboardInputMonitor?

    init() {
        playback.level = Float(volume)
        playback.onActiveNotesChanged = { [weak self] notes in
            self?.activeNotes = notes
        }
    }

    func connect() {
        guard engine == nil else { return }
        do {
            let engine = try MultitouchHapticEngine()
            self.engine = engine
            playback.player = engine
            status = "Trackpad connected"
        } catch {
            status = error.localizedDescription
        }
    }

    func reconnect() {
        disconnect()
        connect()
    }

    func disconnect() {
        playback.releaseAll()
        playback.player = nil
        engine = nil
        status = "Disconnected"
    }

    func pressMouseNote(_ midi: Int) {
        connect()
        guard engine != nil else { return }
        playback.pressMouseNote(midi)
    }

    func releaseMouseNote(_ midi: Int) {
        playback.releaseMouseNote(midi)
    }

    func releaseAll() {
        playback.releaseAll()
    }

    func midiNote(for semitone: Int) -> Int {
        PianoNote.midiNote(octave: octave, semitone: semitone)
    }

    func startKeyboardMonitoring() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = KeyboardInputMonitor(
            onKeyDown: { [weak self] keyCode, semitone in
                self?.pressKeyboardNote(keyCode: keyCode, semitone: semitone)
            },
            onKeyUp: { [weak self] keyCode in
                self?.playback.releaseKeyboardNote(keyCode: keyCode)
            }
        )
    }

    func stopKeyboardMonitoring() {
        keyboardMonitor = nil
        releaseAll()
    }

    private func pressKeyboardNote(keyCode: UInt16, semitone: Int) {
        connect()
        guard engine != nil else { return }
        playback.pressKeyboardNote(keyCode: keyCode, midi: midiNote(for: semitone))
    }
}
