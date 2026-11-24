import SwiftUI
import AppKit
import Foundation
import CoreFoundation
import Darwin

@main
struct HapticPianoApp: App {
    @StateObject private var piano = PianoModel()

    var body: some Scene {
        WindowGroup {
            PianoView()
                .environmentObject(piano)
                .frame(minWidth: 760, minHeight: 520)
        }
        .windowStyle(.titleBar)
    }
}

@MainActor
final class PianoModel: ObservableObject {
    @Published private(set) var status = "Not connected"
    @Published private(set) var activeNotes: Set<Int> = []
    @Published var volume: Double = 0.72
    @Published var octave: Int = 4

    private var engine: HapticEngine?
    private var mouseHeldNotes: Set<Int> = []
    private var keyboardHeldNotes: [UInt16: Int] = [:]
    private var pulseTimer: Timer?
    private var keyboardMonitor: KeyboardInputMonitor?

    func connect() {
        guard engine == nil else { return }
        do {
            let newEngine = try HapticEngine()
            engine = newEngine
            status = "Trackpad connected"
        } catch {
            status = error.localizedDescription
        }
    }

    func disconnect() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        mouseHeldNotes.removeAll()
        keyboardHeldNotes.removeAll()
        activeNotes.removeAll()
        engine = nil
        status = "Disconnected"
    }

    func press(_ midi: Int) {
        if engine == nil {
            connect()
            guard engine != nil else { return }
        }
        mouseHeldNotes.insert(midi)
        updateHeldNotes()
    }

    func release(_ midi: Int) {
        mouseHeldNotes.remove(midi)
        updateHeldNotes()
    }

    func releaseAll() {
        mouseHeldNotes.removeAll()
        keyboardHeldNotes.removeAll()
        updateHeldNotes()
    }

    func startKeyboardMonitoring() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = KeyboardInputMonitor(
            onKeyDown: { [weak self] keyCode, semitone in
                self?.pressKeyboardKey(keyCode, semitone: semitone)
            },
            onKeyUp: { [weak self] keyCode in
                self?.releaseKeyboardKey(keyCode)
            }
        )
    }

    func stopKeyboardMonitoring() {
        keyboardMonitor = nil
        keyboardHeldNotes.removeAll()
        updateHeldNotes()
    }

    private func startPulseTimerIfNeeded() {
        guard pulseTimer == nil else { return }
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.105, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playChord()
            }
        }
    }

    private func pressKeyboardKey(_ keyCode: UInt16, semitone: Int) {
        guard keyboardHeldNotes[keyCode] == nil else { return }
        if engine == nil {
            connect()
            guard engine != nil else { return }
        }
        keyboardHeldNotes[keyCode] = midiNote(semitone: semitone)
        updateHeldNotes()
    }

    private func releaseKeyboardKey(_ keyCode: UInt16) {
        guard keyboardHeldNotes.removeValue(forKey: keyCode) != nil else { return }
        updateHeldNotes()
    }

    private func updateHeldNotes() {
        activeNotes = mouseHeldNotes.union(keyboardHeldNotes.values)
        if activeNotes.isEmpty {
            pulseTimer?.invalidate()
            pulseTimer = nil
        } else {
            startPulseTimerIfNeeded()
            playChord()
        }
    }

    private func playChord() {
        guard let engine, !activeNotes.isEmpty else { return }
        let tones = activeNotes.sorted().map { midi in
            (frequency: Self.frequency(forMIDI: midi), amplitude: 1.0)
        }
        engine.play(tones: tones, level: Float(volume), durationMS: 125)
    }

    static func frequency(forMIDI midi: Int) -> Double {
        440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    func midiNote(semitone: Int) -> Int {
        (octave + 1) * 12 + semitone
    }

}

private final class KeyboardInputMonitor {
    private let onKeyDown: (UInt16, Int) -> Void
    private let onKeyUp: (UInt16) -> Void
    private var monitor: Any?

    // Uses physical key positions so the two octave rows are consistent regardless
    // of the character produced by the active keyboard layout.
    private let semitoneByKeyCode: [UInt16: Int] = [
        6: 0, 1: 1, 7: 2, 2: 3, 8: 4, 9: 5,
        5: 6, 11: 7, 4: 8, 45: 9, 38: 10, 46: 11,
        12: 12, 19: 13, 13: 14, 20: 15, 14: 16, 15: 17,
        23: 18, 17: 19, 22: 20, 16: 21, 26: 22, 32: 23
    ]

    init(onKeyDown: @escaping (UInt16, Int) -> Void, onKeyUp: @escaping (UInt16) -> Void) {
        self.onKeyDown = onKeyDown
        self.onKeyUp = onKeyUp
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, let semitone = self.semitoneByKeyCode[event.keyCode] else { return event }

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

// MARK: - Haptic motor bridge
//
// This uses the same private MultitouchSupport entry points and actuation
// dictionary format as https://github.com/os6/nospeaker.
// Private APIs are undocumented and can change between macOS releases.

private final class HapticEngine {
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
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
            RTLD_NOW
        ) else {
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

    func play(tones: [(frequency: Double, amplitude: Double)], level: Float, durationMS: Double) {
        guard !tones.isEmpty else { return }
        let total = max(tones.reduce(0.0) { $0 + $1.amplitude }, 0.0001)
        let description: [String: Any] = [
            "BaseWaveform": [
                "Type": "Gaussian",
                "Amplitude": 0.0,
                "DurationMS": durationMS
            ],
            "Tones": tones.map { tone in
                [
                    "Type": "Sine",
                    "Amplitude": tone.amplitude / total,
                    "DurationMS": durationMS,
                    "DelayMS": 0.0,
                    "FrequencykHz": tone.frequency / 1000.0
                ]
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

private enum HapticError: LocalizedError {
    case frameworkUnavailable
    case apiUnavailable
    case noTrackpad
    case forceTouchRequired

    var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            return "MultitouchSupport could not be loaded."
        case .apiUnavailable:
            return "This macOS version does not expose the haptic functions used by NO SPEAKER."
        case .noTrackpad:
            return "No trackpad was found. Connect a Force Touch trackpad and try again."
        case .forceTouchRequired:
            return "A Force Touch trackpad is required. Use a MacBook from 2015 or later, or a Magic Trackpad 2 or newer."
        }
    }
}

// MARK: - Piano UI

private struct PianoView: View {
    @EnvironmentObject private var piano: PianoModel
    @Environment(\.scenePhase) private var scenePhase

    private let whiteSemitones = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23]
    private let blackSemitones = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22]

    var body: some View {
        VStack(spacing: 22) {
            header
            controls
            keyboard
            footer
        }
        .padding(28)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            piano.startKeyboardMonitoring()
            piano.connect()
        }
        .onDisappear {
            piano.stopKeyboardMonitoring()
            piano.releaseAll()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { piano.releaseAll() }
        }
        .onChange(of: piano.volume) { _, _ in
            // The next pulse applies the updated level.
        }
        .onExitCommand { piano.releaseAll() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("TRACKPAD PIANO")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .tracking(1.4)
                Text("A small piano. No speakers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(piano.status == "Trackpad connected" ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(piano.status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary, in: Capsule())
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("OCTAVE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button {
                        piano.octave = max(1, piano.octave - 1)
                        piano.releaseAll()
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.bordered)
                    Text("\(piano.octave)")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .frame(width: 22)
                    Button {
                        piano.octave = min(7, piano.octave + 1)
                        piano.releaseAll()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider().frame(height: 42)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("MOTOR LEVEL")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(piano.volume * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $piano.volume, in: 0.15...1.0)
                    .frame(width: 190)
            }

            Spacer()

            Button {
                piano.disconnect()
                piano.connect()
            } label: {
                Label("Reconnect", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var keyboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PLAY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Hold a key to sustain · Chords supported")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            GeometryReader { proxy in
                let keyWidth = proxy.size.width / CGFloat(whiteSemitones.count)
                let blackWidth = keyWidth * 0.58
                let blackHeight = proxy.size.height * 0.62

                ZStack(alignment: .topLeading) {
                    HStack(spacing: 2) {
                        ForEach(whiteSemitones, id: \.self) { semitone in
                            let midi = piano.midiNote(semitone: semitone)
                            PianoKey(
                                title: noteName(semitone),
                                isBlack: false,
                                isPressed: piano.activeNotes.contains(midi),
                                onDown: { piano.press(midi) },
                                onUp: { piano.release(midi) }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }

                    ForEach(blackSemitones, id: \.self) { semitone in
                        let midi = piano.midiNote(semitone: semitone)
                        let precedingWhiteKeys = whiteSemitones.filter { $0 < semitone }.count
                        PianoKey(
                            title: noteName(semitone),
                            isBlack: true,
                            isPressed: piano.activeNotes.contains(midi),
                            onDown: { piano.press(midi) },
                            onUp: { piano.release(midi) }
                        )
                        .frame(width: blackWidth, height: blackHeight)
                        .position(
                            x: CGFloat(precedingWhiteKeys) * keyWidth,
                            y: blackHeight / 2
                        )
                    }
                }
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("Sound is produced by the Force Touch haptic motor. Place the Mac on a hard table for the clearest result. The trackpad is quiet and does not behave like a normal speaker.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Stop all notes") { piano.releaseAll() }
                .buttonStyle(.bordered)
        }
    }

    private func noteName(_ semitone: Int) -> String {
        let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        return names[semitone % 12]
    }
}

private struct PianoKey: View {
    let title: String
    let isBlack: Bool
    let isPressed: Bool
    let onDown: () -> Void
    let onUp: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: isBlack ? 6 : 7)
                .fill(fillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: isBlack ? 6 : 7)
                        .stroke(isBlack ? Color.black.opacity(0.55) : Color.black.opacity(0.17), lineWidth: 1)
                }
                .shadow(color: .black.opacity(isBlack ? 0.28 : 0.08), radius: isBlack ? 5 : 2, y: isBlack ? 4 : 2)

            Text(title)
                .font(.system(size: isBlack ? 9 : 11, weight: .medium))
                .foregroundStyle(isBlack ? Color.white.opacity(0.76) : Color.black.opacity(0.52))
                .padding(.bottom, 12)

            MouseHoldView(onDown: onDown, onUp: onUp)
                .background(Color.clear)
        }
        .scaleEffect(isPressed ? 0.985 : 1)
        .animation(.easeOut(duration: 0.06), value: isPressed)
    }

    private var fillColor: Color {
        if isBlack {
            return isPressed ? Color(white: 0.25) : Color(white: 0.10)
        }
        return isPressed ? Color(red: 0.80, green: 0.86, blue: 0.92) : Color(white: 0.97)
    }
}

private struct MouseHoldView: NSViewRepresentable {
    let onDown: () -> Void
    let onUp: () -> Void

    func makeNSView(context: Context) -> HoldNSView {
        let view = HoldNSView()
        view.onDown = onDown
        view.onUp = onUp
        return view
    }

    func updateNSView(_ nsView: HoldNSView, context: Context) {
        nsView.onDown = onDown
        nsView.onUp = onUp
    }

    static func dismantleNSView(_ nsView: HoldNSView, coordinator: ()) {
        nsView.finishPress()
    }
}

private final class HoldNSView: NSView {
    var onDown: (() -> Void)?
    var onUp: (() -> Void)?
    private var isDown = false

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard !isDown else { return }
        isDown = true
        onDown?()
    }

    override func mouseUp(with event: NSEvent) {
        finishPress()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
    }

    func finishPress() {
        guard isDown else { return }
        isDown = false
        onUp?()
    }
}
