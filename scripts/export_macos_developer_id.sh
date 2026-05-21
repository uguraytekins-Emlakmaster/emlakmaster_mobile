#!/usr/bin/env bash
# Archive + Developer ID export (Xcode otomatik sertifika indirebilir).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/macos"

ARCHIVE="$ROOT/build/macos/archive/Runner.xcarchive"
EXPORT_DIR="$ROOT/build/macos/export"
PLIST="$ROOT/macos/ExportOptions-developer-id.plist"

echo "=== macOS Developer ID export ==="
mkdir -p "$(dirname "$ARCHIVE")" "$EXPORT_DIR"

xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  archive 2>&1 | tail -30

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$PLIST" \
  -allowProvisioningUpdates 2>&1 | tail -20

APP_SRC="$EXPORT_DIR/emlakmaster_mobile.app"
APP_DST="$ROOT/build/macos/Build/Products/Release/emlakmaster_mobile.app"
if [[ -d "$APP_SRC" ]]; then
  rm -rf "$APP_DST"
  mkdir -p "$(dirname "$APP_DST")"
  cp -R "$APP_SRC" "$APP_DST"
  echo "Release app güncellendi: $APP_DST"
  codesign -dvv "$APP_DST" 2>&1 | awk -F= '/^Authority=/{print; exit}'
fi
