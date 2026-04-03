#!/bin/bash
set -euo pipefail

BINARY_PATH="${1:-.build/release/TapLockApp}"
APP_NAME="TapLock"
BUNDLE_DIR="${APP_NAME}.app"
PLIST_SRC="Sources/TapLockApp/Info.plist"
ICON_SRC="Resources/AppIcon.icns"

echo "Creating ${BUNDLE_DIR}..."

rm -rf "${BUNDLE_DIR}"

mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp "${BINARY_PATH}" "${BUNDLE_DIR}/Contents/MacOS/TapLockApp"
cp "${PLIST_SRC}" "${BUNDLE_DIR}/Contents/Info.plist"

if [ -f "${ICON_SRC}" ]; then
    cp "${ICON_SRC}" "${BUNDLE_DIR}/Contents/Resources/AppIcon.icns"
fi

codesign --force --deep --sign - --identifier com.ugurcandede.taplock "${BUNDLE_DIR}"

echo "Done: ${BUNDLE_DIR}"
echo "Run with: open ${BUNDLE_DIR}"

