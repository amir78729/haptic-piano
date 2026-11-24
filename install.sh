#!/usr/bin/env sh
set -eu

REPOSITORY="amir78729/haptic-piano"
VERSION="${HAPTIC_PIANO_VERSION:-v0.2.3}"
INSTALL_DIR="${HAPTIC_PIANO_INSTALL_DIR:-$HOME/Applications}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/haptic-piano.XXXXXX")"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT HUP INT TERM

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Haptic Piano requires macOS." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to download Haptic Piano." >&2
    exit 1
fi

if ! command -v swiftc >/dev/null 2>&1; then
    echo "Xcode Command Line Tools are required." >&2
    echo "Install them with: xcode-select --install" >&2
    exit 1
fi

ARCHIVE="$WORK_DIR/haptic-piano.tar.gz"
SOURCE_URL="https://github.com/$REPOSITORY/archive/refs/tags/$VERSION.tar.gz"

echo "Downloading Haptic Piano $VERSION..."
curl --fail --location --silent --show-error "$SOURCE_URL" --output "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$WORK_DIR"

SOURCE_DIR="$WORK_DIR/haptic-piano-${VERSION#v}"
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Downloaded source archive had an unexpected layout." >&2
    exit 1
fi

echo "Building Haptic Piano..."
(cd "$SOURCE_DIR" && ./build.sh)

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/HapticPiano.app"
cp -R "$SOURCE_DIR/build/HapticPiano.app" "$INSTALL_DIR/HapticPiano.app"

echo "Installed Haptic Piano to $INSTALL_DIR/HapticPiano.app"
echo "Open it with: open \"$INSTALL_DIR/HapticPiano.app\""
