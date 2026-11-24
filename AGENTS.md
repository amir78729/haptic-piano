# Haptic Piano Agent Guide

## Project Purpose

Haptic Piano is a native macOS instrument that renders musical sine tones with
the Force Touch trackpad motor. It is not a speaker-based audio app. It uses
Apple's private, undocumented `MultitouchSupport` framework and is therefore
experimental, unsupported, and not App Store compatible.

## Non-Negotiable Constraints

- Target macOS 12 or later. Do not introduce iOS, iPadOS, or cross-platform
  assumptions.
- Keep the project dependency-free unless a dependency is necessary for the
  haptic instrument itself.
- Never raise haptic output above the existing clamped `1.0` motor level.
- Keep all private-framework loading, symbols, and ownership details in
  `Sources/HapticPiano/Haptics/MultitouchHapticEngine.swift`.
- Do not claim haptic behavior is identical across Mac or Magic Trackpad
  models. Hardware output requires manual testing on a Force Touch trackpad.
- Do not commit generated `build/`, `.build/`, DMG, release, or personal Xcode
  files.

## Architecture

`Package.swift` defines three targets:

| Target | Path | Responsibility |
| --- | --- | --- |
| `HapticPianoCore` | `Sources/HapticPiano/Domain/` | Platform-independent note math and piano layout. |
| `HapticPiano` | `Sources/HapticPiano/` except `Domain/` | macOS SwiftUI app, AppKit input, haptic playback. |
| `HapticPianoChecks` | `Verification/HapticPianoChecks.swift` | Dependency-free executable checks for domain behavior. |

### Source Ownership

- `Domain/`: MIDI conversion, frequencies, note labels, and keyboard layout.
  Keep this target free of SwiftUI, AppKit, and haptic-framework dependencies.
- `App/PianoStore.swift`: the `@MainActor` observable state and public actions
  that UI views invoke. Put interaction state and UI-to-playback mapping here.
- `App/PlaybackCoordinator.swift`: owns held-note state, timer-driven playback,
  and assembly of `HapticTone` values. Keep it UI-independent.
- `Haptics/`: the haptic-player protocol and the private-framework bridge.
  Preserve the `HapticPlaying` protocol to keep playback testable and isolated.
- `Input/`: AppKit-backed SwiftUI representables for pointer/keyboard events.
  Always end an active press when a representable is dismantled.
- `UI/`: SwiftUI composition and visual state. Views should delegate playback
  actions to `PianoStore`, not call the haptic engine directly.
- `HapticPianoApp.swift`: app lifecycle, root views, and tab selection only.

## Interaction and Playback Rules

- Piano notes sustain only while their mouse or keyboard input remains held.
- Releasing a note, switching tabs, app inactivity, and Exit must release
  active haptic playback.
- Chords are simultaneous tones; shared motor amplitude can make them weaker.
- Microtonal mode uses one continuous tone. The base note comes from its
  selector; relative pointer movement maps horizontal deltas to pitch and
  vertical deltas to volume.
- The current microtonal mapping is 200 points for each endpoint: horizontal
  movement reaches plus or minus one octave; vertical movement reaches silence
  downward or full volume upward. Preserve this behavior unless requirements
  explicitly change it.
- New input modes must work without pressure sensing. Do not depend on Force
  Touch pressure APIs.

## Development Workflow

Use the Makefile as the standard project interface:

```sh
make test      # Run HapticPianoChecks
make build     # Build build/HapticPiano.app
make verify    # Required automated check: test then build
make run       # Build and launch the app
```

- Run `make verify` for every change before finishing.
- Run `git diff --check` before committing.
- When changing note math or keyboard layout, add or update the focused checks
  in `Verification/HapticPianoChecks.swift`.
- When changing playback or input, manually test mouse input, computer-keyboard
  input, octave switching, chords, reconnecting, tab changes, and note release
  after app inactivity on Force Touch hardware when available.
- When changing controls, requirements, installation, or limitations, update
  `README.md`.
- When changing `build.sh`, app-bundle paths, or source layout, test the
  installer against a tag with
  `HAPTIC_PIANO_VERSION=<tag> ./install.sh`.

## Style and Scope

- Follow the existing Swift style: concise types, explicit access only where it
  communicates an API boundary, and no third-party abstractions.
- Prefer focused changes that respect the directory ownership above. Avoid
  unrelated refactors.
- Keep UI text direct and concise. Use SF Symbols through `Image(systemName:)`
  for recognizable controls.
- Use `@MainActor` for UI state and timer-backed playback coordination. Do not
  mutate `PianoStore` published properties from background work.
- Preserve the public behavior of existing piano controls while adding modes or
  features.

## Git and Releases

- Work from `main` unless the task specifies a branch.
- Inspect `git status` before edits and never discard unrelated user changes.
- Use descriptive, focused commits. Do not amend, reset, or force-push branches
  without explicit authorization.
- Releases are driven by annotated `vX.Y.Z` tags pushed after the release commit
  is on `main`.
- `.github/workflows/release.yml` builds a DMG on `macos-13`, generates a
  checksum, and creates the GitHub Release. Do not change the runner or release
  workflow without validating its macOS availability and tag behavior.
- If a release tag must be moved, treat it as a deliberate release correction:
  state the impact, force-update only that tag, and verify the new Actions run.

## Useful Files

- `README.md`: user-facing requirements, controls, installation, and limits.
- `CONTRIBUTING.md`: contributor expectations and manual hardware-test scope.
- `Package.swift`: target boundaries and supported platform.
- `build.sh`: creates the distributable `.app` bundle.
- `install.sh`: installs a tagged source build to an application directory.
- `.github/workflows/release.yml`: tagged DMG release automation.
