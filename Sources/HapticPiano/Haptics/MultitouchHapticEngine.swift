import CoreFoundation
import Darwin
import Foundation

// Apple's MultitouchSupport framework is private and undocumented. Keep all
// dynamic-symbol and Core Foundation ownership details confined to this file.
final class MultitouchHapticEngine: HapticPlaying {
    private typealias CreateList = @convention(c) () -> Unmanaged<CFArray>?
    private typealias GetID = @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<UInt64>) -> Int32
    private typealias IsBuiltIn = @convention(c) (UnsafeMutableRawPointer) -> Bool
    private typealias ActuatorCreate = @convention(c) (UInt64) -> Unmanaged<CFTypeRef>?
    private typealias ActuatorOpen = @convention(c) (CFTypeRef) -> Int32
    private typealias ActuatorClose = @convention(c) (CFTypeRef) -> Int32
    private typealias ActuationCreate = @convention(c) (CFDictionary, Int32) -> UnsafeMutableRawPointer?
    private typealias ActuationPlay = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UInt32, Float, Float) -> Int32

    private let framework: UnsafeMutableRawPointer
    private let actuator: CFTypeRef
    private let motorPointer: UnsafeMutableRawPointer
    private let createActuation: ActuationCreate
    private let playActuation: ActuationPlay
    private let closeActuator: ActuatorClose

    init() throws {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) else {
            throw HapticError.frameworkUnavailable
        }
        framework = handle

        func symbol<T>(_ name: String, as type: T.Type) -> T? {
            guard let address = dlsym(handle, name) else { return nil }
            return unsafeBitCast(address, to: type)
        }

        guard
            let createList = symbol("MTDeviceCreateList", as: CreateList.self),
            let getID = symbol("MTDeviceGetDeviceID", as: GetID.self),
            let isBuiltIn = symbol("MTDeviceIsBuiltIn", as: IsBuiltIn.self),
            let createActuator = symbol("MTActuatorCreateFromDeviceID", as: ActuatorCreate.self),
            let openActuator = symbol("MTActuatorOpen", as: ActuatorOpen.self),
            let closeActuator = symbol("MTActuatorClose", as: ActuatorClose.self),
            let createActuation = symbol("MTActuationCreateFromDictionary", as: ActuationCreate.self),
            let playActuation = symbol("MTActuationActuate", as: ActuationPlay.self)
        else {
            dlclose(handle)
            throw HapticError.apiUnavailable
        }

        guard let devices = createList()?.takeRetainedValue(), CFArrayGetCount(devices) > 0 else {
            dlclose(handle)
            throw HapticError.noTrackpad
        }

        var candidates: [(id: UInt64, builtIn: Bool)] = []
        for index in 0..<CFArrayGetCount(devices) {
            guard let raw = CFArrayGetValueAtIndex(devices, index) else { continue }
            let device = UnsafeMutableRawPointer(mutating: raw)
            var id: UInt64 = 0
            if getID(device, &id) == 0 {
                candidates.append((id, isBuiltIn(device)))
            }
        }

        var opened: CFTypeRef?
        for candidate in candidates.sorted(by: { $0.builtIn && !$1.builtIn }) {
            guard let reference = createActuator(candidate.id)?.takeRetainedValue() else { continue }
            if openActuator(reference) == 0 {
                opened = reference
                break
            }
        }

        guard let opened else {
            dlclose(handle)
            throw HapticError.forceTouchRequired
        }

        actuator = opened
        motorPointer = Unmanaged.passUnretained(opened as AnyObject).toOpaque()
        self.createActuation = createActuation
        self.playActuation = playActuation
        self.closeActuator = closeActuator
    }

    func play(tones: [HapticTone], level: Float, durationMS: Double) {
        guard !tones.isEmpty else { return }
        let total = max(tones.reduce(0.0) { $0 + $1.amplitude }, 0.0001)
        let description: [String: Any] = [
            "BaseWaveform": ["Type": "Gaussian", "Amplitude": 0.0, "DurationMS": durationMS],
            "Tones": tones.map {
                ["Type": "Sine", "Amplitude": $0.amplitude / total, "DurationMS": durationMS,
                 "DelayMS": 0.0, "FrequencykHz": $0.frequency / 1000.0]
            }
        ]

        guard let actuation = createActuation(description as CFDictionary, 0) else { return }
        _ = playActuation(actuation, motorPointer, 0, min(1, max(0, level)), 0)
        Unmanaged<AnyObject>.fromOpaque(actuation).release()
    }

    deinit {
        _ = closeActuator(actuator)
        dlclose(framework)
    }
}
