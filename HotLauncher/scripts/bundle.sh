#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PRODUCT="HotLauncher"
BUNDLE_ID="com.hwemochung.hotlauncher"
BUILD_DIR=".build/release"
APP_DIR="$PRODUCT.app/Contents"
ENTITLEMENTS="scripts/HotLauncher.entitlements"
ICON="$APP_DIR/Resources/AppIcon.icns"

echo "Building $PRODUCT..."
swift build -c release 2>&1

rm -rf "$PRODUCT.app"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

cp "$BUILD_DIR/${PRODUCT}App" "$APP_DIR/MacOS/$PRODUCT"

swift scripts/MakeIcon.swift "$ICON"

cat > "$APP_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>HotLauncher</string>
    <key>CFBundleDisplayName</key>
    <string>HotLauncher</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>HotLauncher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>HotLauncher launches applications you pick in Settings.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2026</string>
</dict>
</plist>
PLIST

IDENTITY="${CODESIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
    IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application/{print $2; exit}')"
fi
if [[ -z "$IDENTITY" ]]; then
    IDENTITY="-"
    echo "No Developer ID; adhoc + hardened runtime. Notarization will not pass."
fi

codesign --force --sign "$IDENTITY" --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --identifier "$BUNDLE_ID" \
    "$PRODUCT.app"

echo "Built $PRODUCT.app"
echo "Identifier $BUNDLE_ID signed as $IDENTITY"
echo "Install: bash scripts/install.sh"
