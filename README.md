# Haptic Piano

A small native macOS piano. It sends musical sine tones to a Mac's Force Touch
trackpad haptic motor. It does not use the Mac speakers.

> [!WARNING]
> Haptic Piano is an experimental project built on Apple's private,
> undocumented `MultitouchSupport` framework. It is not App Store compatible,
> may stop working after a macOS update, and is used at your own risk.

## Requirements

- macOS 12 or later
- A Force Touch trackpad: built-in MacBook trackpad (2015 or later), or Magic Trackpad 2+
- Xcode Command Line Tools

## Build and run

```sh
xcode-select --install
make run
```

The Makefile is the standard command interface. It uses Swift Package Manager
and creates a minimal `.app` bundle with no third-party packages.

```sh
make build    # Create build/HapticPiano.app
make test     # Check note calculations and keyboard mapping
make verify   # Run checks and build the app bundle
make install  # Build and install to ~/Applications
make clean    # Remove build/ and .build/
```

## Install

To download the tagged source, build it locally, and install the app to
`~/Applications`, run:

```sh
curl -fsSL https://raw.githubusercontent.com/amir78729/haptic-piano/main/install.sh | sh
```

The installer requires Xcode Command Line Tools and defaults to version
`v0.2.2`. To install another tagged version or a different application folder:

```sh
curl -fsSL https://raw.githubusercontent.com/amir78729/haptic-piano/main/install.sh | \
  HAPTIC_PIANO_VERSION=v0.2.2 HAPTIC_PIANO_INSTALL_DIR="$HOME/Applications" sh
```

This installer builds from source; it does not download or run a prebuilt app.
Review [`install.sh`](install.sh) before running it if you prefer not to pipe a
remote script into a shell.

## Releases

Each pushed version tag, such as `v0.2.3`, automatically builds a DMG and
publishes it to [GitHub Releases](https://github.com/amir78729/haptic-piano/releases).
The DMG contains `HapticPiano.app`, an `Applications` shortcut, and a SHA-256
checksum file. Releases are not code-signed or notarized, so macOS may require
manual approval before opening the app.

## How it works

The haptic bridge adapts the motor-control approach from
[os6/nospeaker](https://github.com/os6/nospeaker), by Cody Collier, which is
licensed under MIT. Haptic Piano dynamically loads Apple's private
`MultitouchSupport` framework, finds a Force Touch actuator, and calls
`MTActuationCreateFromDictionary` and `MTActuationActuate`.

The UI holds notes while the mouse button is down. A short actuation is sent
repeatedly while notes remain held. Multiple held notes are sent as simultaneous
sine tones.

## Important limitations

- `MultitouchSupport` is private and undocumented. A macOS update can break it,
  and the app cannot be distributed through the Mac App Store.
- The app has been compiled with Xcode Command Line Tools, but haptic output has
  not been verified on every Mac or Force Touch trackpad model.
- Trackpad output is quiet and frequency response varies by Mac model.
- Chords share the motor's available amplitude. More simultaneous notes can
  sound weaker.
- This is an experimental sound instrument, not a replacement for a speaker.
- Keep the motor level at or below the normal maximum. The app clamps it to 1.0.

## Controls

- Hold a piano key with the mouse to play it.
- Hold more than one key to play a chord.
- Play the lower octave with `Z S X D C V G B H N J M`, and the upper octave
  with `Q 2 W 3 E R 5 T 6 Y 7 U`. The black-key letters/numbers are arranged
  above their neighboring white keys like a piano keyboard.
- Change octave with `-` and `+`.
- Adjust motor level with the slider.
- Use **Stop all notes** if a note remains active.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build checks, hardware-test
expectations, and bug-report details.

## License

Haptic Piano is available under the [MIT License](LICENSE).
