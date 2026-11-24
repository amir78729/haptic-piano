# Contributing to Haptic Piano

Contributions are welcome, especially compatibility reports and focused fixes
for different Mac and Force Touch trackpad models.

## Before you begin

- This project uses Apple's private `MultitouchSupport` framework. Changes
  must preserve the explicit experimental and unsupported nature of that API.
- Do not increase haptic output beyond the app's clamped `1.0` motor level.
- Keep the project dependency-free unless a dependency clearly improves the
  haptic instrument itself.

## Development

Requirements: macOS 12 or later, Xcode Command Line Tools, and a Force Touch
trackpad for hardware testing.

```sh
./build.sh
open build/HapticPiano.app
```

`make verify` is the required automated check for every change. Test mouse input,
computer-keyboard input, octave switching, chords, reconnecting, and releasing
notes after the app becomes inactive when the change affects playback or input.

When changing `build.sh`, app-bundle paths, or source layout, also test the
installer with `HAPTIC_PIANO_VERSION=<tag> ./install.sh`. The installer must
continue to build a tagged source archive and install only to the selected
application directory.

## Pull requests

- Keep changes narrowly focused and explain their behavioral impact.
- Update `README.md` when controls, requirements, build instructions, or known
  limitations change.
- Do not commit `build/` output or personal Xcode state.
- State the macOS version and trackpad hardware used for testing in the pull
  request description.

## Bug reports

Please include your macOS version, Mac model or external trackpad model,
whether the trackpad is built-in or external, the app's connection status, and
clear reproduction steps. Hardware-specific reports are especially useful.
