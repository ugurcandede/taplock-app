#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_PNG="${1:-AppIcon.png}"
OUTPUT="$PROJECT_DIR/Resources/AppIcon.icns"

if [ ! -f "$SOURCE_PNG" ]; then
    echo "Generating icon PNG..."
    swift "$SCRIPT_DIR/generate-icon.swift"
    SOURCE_PNG="AppIcon.png"
fi

echo "Creating .icns from $SOURCE_PNG..."

ICONSET="AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

sips -z 16 16     "$SOURCE_PNG" --out "$ICONSET/icon_16x16.png"      > /dev/null
sips -z 32 32     "$SOURCE_PNG" --out "$ICONSET/icon_16x16@2x.png"   > /dev/null
sips -z 32 32     "$SOURCE_PNG" --out "$ICONSET/icon_32x32.png"      > /dev/null
sips -z 64 64     "$SOURCE_PNG" --out "$ICONSET/icon_32x32@2x.png"   > /dev/null
sips -z 128 128   "$SOURCE_PNG" --out "$ICONSET/icon_128x128.png"    > /dev/null
sips -z 256 256   "$SOURCE_PNG" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$SOURCE_PNG" --out "$ICONSET/icon_256x256.png"    > /dev/null
sips -z 512 512   "$SOURCE_PNG" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$SOURCE_PNG" --out "$ICONSET/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$SOURCE_PNG" --out "$ICONSET/icon_512x512@2x.png" > /dev/null

mkdir -p "$(dirname "$OUTPUT")"
iconutil -c icns "$ICONSET" -o "$OUTPUT"
rm -rf "$ICONSET"

echo "Done: $OUTPUT"
