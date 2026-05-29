#!/bin/bash
# Build Barred Awake and assemble a menu-bar .app bundle.
set -euo pipefail
cd "$(dirname "$0")"

APP="Barred Awake"
BUNDLE_ID="com.noahjohnson.barredawake"
CONFIG="${1:-release}"

echo "▶ Compiling ($CONFIG)…"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/BarredAwake"

APPDIR="build/$APP.app"
echo "▶ Assembling ${APPDIR}…"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/Contents/MacOS" "$APPDIR/Contents/Resources"
cp "$BIN" "$APPDIR/Contents/MacOS/BarredAwake"

cat > "$APPDIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP</string>
    <key>CFBundleDisplayName</key>     <string>$APP</string>
    <key>CFBundleExecutable</key>      <string>BarredAwake</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so login-item registration (SMAppService) works locally.
codesign --force --deep --sign - "$APPDIR" 2>/dev/null || true

echo "✅ Built $APPDIR"
echo "   Run it with:  open \"$APPDIR\""
