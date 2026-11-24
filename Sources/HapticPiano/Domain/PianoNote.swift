import Foundation

public enum PianoNote {
    public static func frequency(forMIDI midi: Int) -> Double {
        440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    public static func midiNote(octave: Int, semitone: Int) -> Int {
        (octave + 1) * 12 + semitone
    }

    public static func name(for semitone: Int) -> String {
        let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        return names[semitone % 12]
    }
}
