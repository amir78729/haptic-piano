import Foundation

enum HapticError: LocalizedError {
    case frameworkUnavailable
    case apiUnavailable
    case noTrackpad
    case forceTouchRequired

    var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            return "MultitouchSupport could not be loaded."
        case .apiUnavailable:
            return "This macOS version does not expose the haptic functions required by Haptic Piano."
        case .noTrackpad:
            return "No trackpad was found. Connect a Force Touch trackpad and try again."
        case .forceTouchRequired:
            return "A Force Touch trackpad is required. Use a MacBook from 2015 or later, or a Magic Trackpad 2 or newer."
        }
    }
}
