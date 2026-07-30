#!/bin/bash
# Rasterizes the dinosaur source SVGs (design/) into the asset catalog.
# Requires rsvg-convert (brew install librsvg).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="design"
AI="Cliposaurus/Assets.xcassets/AppIcon.appiconset"
MB="Cliposaurus/Assets.xcassets/MenuBarIcon.imageset"

for s in 16 32 64 128 256 512 1024; do
  rsvg-convert -w "$s" -h "$s" "$SRC/appicon.svg" -o "$AI/icon_${s}.png"
done

rsvg-convert -w 18 -h 18 "$SRC/menubar.svg" -o "$MB/menubar_18.png"
rsvg-convert -w 36 -h 36 "$SRC/menubar.svg" -o "$MB/menubar_36.png"
rsvg-convert -w 54 -h 54 "$SRC/menubar.svg" -o "$MB/menubar_54.png"

echo "Icons rasterized."
