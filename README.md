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
./build.sh
open build/HapticPiano.app
```

The build script uses Swift Package Manager and creates a minimal `.app` bundle.
No third-party packages are required.

## Install

To download the tagged source, build it locally, and install the app to
`~/Applications`, run:

```sh
curl -fsSL https://raw.githubusercontent.com/amir78729/haptic-piano/main/install.sh | sh
```

The installer requires Xcode Command Line Tools and defaults to version
`v0.2.0`. To install another tagged version or a different application folder:

```sh
curl -fsSL https://raw.githubusercontent.com/amir78729/haptic-piano/main/install.sh | \
  HAPTIC_PIANO_VERSION=v0.2.0 HAPTIC_PIANO_INSTALL_DIR="$HOME/Applications" sh
```

This installer builds from source; it does not download or run a prebuilt app.
Review [`install.sh`](install.sh) before running it if you prefer not to pipe a
remote script into a shell.

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
