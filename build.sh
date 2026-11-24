#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/HapticPiano.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Install Xcode Command Line Tools with:"
  echo "  xcode-select --install"
  exit 1
fi

rm -rf "$APP"
mkdir -p "$MACOS"

swift build --package-path "$ROOT" -c release --product HapticPiano
cp "$ROOT/.build/release/HapticPiano" "$MACOS/HapticPiano"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HapticPiano</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.HapticPiano</string>
    <key>CFBundleName</key>
    <string>Haptic Piano</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built: $APP"
echo "Run: open \"$APP\""
