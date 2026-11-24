import Foundation

struct HapticTone {
    let frequency: Double
    let amplitude: Double
}

protocol HapticPlaying: AnyObject {
    func play(tones: [HapticTone], level: Float, durationMS: Double)
}
