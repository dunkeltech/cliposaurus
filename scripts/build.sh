#!/bin/bash
# Builds Cliposaurus in an environment sanitized from Nix/devenv.
#
# An active Nix devenv sets DEVELOPER_DIR/SDKROOT/NIX_LDFLAGS/LD/CC etc. to Nix
# toolchains and thereby hijacks Xcode's linker. We remove these variables and
# force the regular Apple toolchain.
set -euo pipefail

cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null && xcodegen generate

exec env \
  -u DEVELOPER_DIR \
  -u SDKROOT \
  -u NIX_CFLAGS_COMPILE \
  -u NIX_LDFLAGS \
  -u NIX_LDFLAGS_FOR_BUILD \
  -u NIX_CC \
  -u NIX_BINTOOLS \
  -u NIX_CC_WRAPPER_TARGET_HOST_arm64_apple_darwin \
  -u NIX_BINTOOLS_WRAPPER_TARGET_HOST_arm64_apple_darwin \
  -u NIX_IGNORE_LD_THROUGH_GCC \
  -u NIX_HARDENING_ENABLE \
  -u NIX_DONT_SET_RPATH \
  -u LD -u CC -u CXX \
  -u MACOSX_DEPLOYMENT_TARGET \
  PATH="/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin" \
  xcodebuild \
    -project Cliposaurus.xcodeproj \
    -scheme Cliposaurus \
    -configuration Debug \
    -destination 'platform=macOS' \
    -derivedDataPath build \
    "${@:-build}"
