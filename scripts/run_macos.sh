#!/usr/bin/env bash
# macOS: shield + xcodebuild (provisioning) + uygulamayı aç.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/shield/shield.sh" --quiet

echo ">>> macOS build (Xcode + Flutter assemble)..."
xcodebuild \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -allowProvisioningUpdates \
  build

APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug -name 'emlakmaster_mobile.app' -maxdepth 1 2>/dev/null | head -1)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  APP_PATH="$ROOT/build/macos/Build/Products/Debug/emlakmaster_mobile.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: emlakmaster_mobile.app bulunamadı."
  exit 1
fi

echo ">>> Uygulama açılıyor: $APP_PATH"
pkill -x emlakmaster_mobile 2>/dev/null || true
open "$APP_PATH"
