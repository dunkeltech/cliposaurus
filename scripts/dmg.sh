#!/bin/bash
# Builds Cliposaurus as Release and packages it into a distributable DMG
# (with a drag-to-Applications symlink). Environment is sanitized from Nix/devenv.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Cliposaurus"
DERIVED="build"
DIST="dist"
STAGE="$(mktemp -d)"

command -v xcodegen >/dev/null && xcodegen generate

# --- Release build in a sanitized environment ---
env \
  -u DEVELOPER_DIR -u SDKROOT -u NIX_CFLAGS_COMPILE -u NIX_LDFLAGS \
  -u NIX_LDFLAGS_FOR_BUILD -u NIX_CC -u NIX_BINTOOLS \
  -u NIX_CC_WRAPPER_TARGET_HOST_arm64_apple_darwin \
  -u NIX_BINTOOLS_WRAPPER_TARGET_HOST_arm64_apple_darwin \
  -u NIX_IGNORE_LD_THROUGH_GCC -u NIX_HARDENING_ENABLE -u NIX_DONT_SET_RPATH \
  -u LD -u CC -u CXX -u MACOSX_DEPLOYMENT_TARGET \
  PATH="/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin" \
  xcodebuild \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED" \
    build

APP="$DERIVED/Build/Products/Release/${APP_NAME}.app"
[ -d "$APP" ] || { echo "App not found: $APP" >&2; exit 1; }

# Read the version from the BUILT app (where build variables are resolved).
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo 1.0)"
DMG="$DIST/${APP_NAME}-${VERSION}.dmg"

# --- Assemble DMG contents ---
mkdir -p "$DIST"
rm -f "$DMG"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG"

rm -rf "$STAGE"
echo ""
echo "DMG created: $DMG"
ls -lh "$DMG"
