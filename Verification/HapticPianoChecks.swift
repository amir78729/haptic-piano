import Foundation
import HapticPianoCore

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("Check failed: \(message)\n".utf8))
        exit(1)
    }
}

require(PianoNote.frequency(forMIDI: 69) == 440.0, "MIDI note 69 must be 440 Hz")
require(PianoNote.midiNote(octave: 4, semitone: 0) == 60, "C4 must be MIDI note 60")
require(PianoNote.midiNote(octave: 4, semitone: 9) == 69, "A4 must be MIDI note 69")
require(PianoNote.frequency(forMIDI: 60) * pow(2.0, 1.0) == PianoNote.frequency(forMIDI: 72), "one octave bend must double frequency")
require(PianoLayout.semitoneByKeyCode.count == 24, "keyboard mapping must cover two octaves")
require(PianoLayout.semitoneByKeyCode[6] == 0 && PianoLayout.semitoneByKeyCode[32] == 23, "keyboard endpoints must map to C notes")

print("Haptic Piano checks passed")
