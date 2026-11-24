import Foundation
import HapticPianoCore

@MainActor
final class PlaybackCoordinator {
    // MultitouchSupport has no public stop call for an in-flight actuation.
    // Longer overlapping windows reduce the audible re-attack while keeping
    // note release and chord changes responsive.
    private static let actuationDurationMS = 600.0
    private static let refreshInterval = 0.5

    var onActiveNotesChanged: ((Set<Int>) -> Void)?
    var level: Float = 0.72
    var player: HapticPlaying?

    private var mouseHeldNotes: Set<Int> = []
    private var keyboardHeldNotes: [UInt16: Int] = [:]
    private var microtonalFrequency: Double?
    private var microtonalLevel: Float = 0.72
    private var pulseTimer: Timer?

    func pressMouseNote(_ midi: Int) {
        mouseHeldNotes.insert(midi)
        updatePlayback()
    }

    func releaseMouseNote(_ midi: Int) {
        mouseHeldNotes.remove(midi)
        updatePlayback()
    }

    func pressKeyboardNote(keyCode: UInt16, midi: Int) {
        guard keyboardHeldNotes[keyCode] == nil else { return }
        keyboardHeldNotes[keyCode] = midi
        updatePlayback()
    }

    func releaseKeyboardNote(keyCode: UInt16) {
        guard keyboardHeldNotes.removeValue(forKey: keyCode) != nil else { return }
        updatePlayback()
    }

    func startMicrotonalNote(frequency: Double, level: Float) {
        microtonalFrequency = frequency
        microtonalLevel = level
        updatePlayback()
    }

    func updateMicrotonalNote(frequency: Double, level: Float) {
        guard microtonalFrequency != nil else { return }
        microtonalFrequency = frequency
        microtonalLevel = level
        playCurrentNotes()
    }

    func releaseMicrotonalNote() {
        guard microtonalFrequency != nil else { return }
        microtonalFrequency = nil
        updatePlayback()
    }

    func releaseAll() {
        mouseHeldNotes.removeAll()
        keyboardHeldNotes.removeAll()
        microtonalFrequency = nil
        updatePlayback()
    }

    private func updatePlayback() {
        let activeNotes = mouseHeldNotes.union(keyboardHeldNotes.values)
        onActiveNotesChanged?(activeNotes)
        if activeNotes.isEmpty && microtonalFrequency == nil {
            pulseTimer?.invalidate()
            pulseTimer = nil
        } else {
            startPulseTimerIfNeeded()
            play(notes: activeNotes)
        }
    }

    private func startPulseTimerIfNeeded() {
        guard pulseTimer == nil else { return }
        pulseTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playCurrentNotes()
            }
        }
    }

    private func playCurrentNotes() {
        play(notes: mouseHeldNotes.union(keyboardHeldNotes.values))
    }

    private func play(notes: Set<Int>) {
        guard let player else { return }
        var tones = notes.sorted().map { HapticTone(frequency: PianoNote.frequency(forMIDI: $0), amplitude: 1.0) }
        if let microtonalFrequency {
            tones.append(HapticTone(frequency: microtonalFrequency, amplitude: 1.0))
        }
        guard !tones.isEmpty else { return }
        player.play(
            tones: tones,
            level: microtonalFrequency == nil ? level : microtonalLevel,
            durationMS: Self.actuationDurationMS
        )
    }
}
