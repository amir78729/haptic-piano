import Foundation

public enum PianoLayout {
    public static let whiteSemitones = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23]
    public static let blackSemitones = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22]

    // Physical key positions keep the layout consistent across keyboard layouts.
    public static let semitoneByKeyCode: [UInt16: Int] = [
        6: 0, 1: 1, 7: 2, 2: 3, 8: 4, 9: 5,
        5: 6, 11: 7, 4: 8, 45: 9, 38: 10, 46: 11,
        12: 12, 19: 13, 13: 14, 20: 15, 14: 16, 15: 17,
        23: 18, 17: 19, 22: 20, 16: 21, 26: 22, 32: 23
    ]
}
