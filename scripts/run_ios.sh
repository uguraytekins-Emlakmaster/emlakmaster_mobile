#!/usr/bin/env bash
# Shield + iOS simülatör/cihazda çalıştır. Emülatör yoksa otomatik başlatır.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
"$SCRIPT_DIR/shield/shield.sh" --quiet 2>/dev/null || true
if ! flutter devices 2>/dev/null | grep -q "ios"; then
  echo "iOS cihaz yok, simülatör başlatılıyor..."
  flutter emulators --launch apple_ios_simulator 2>/dev/null || true
  sleep 12
fi
# -d ios bazen eşleşmez; ilk iOS cihaz ID'sini kullan (örn. iPhone 16e • UUID • ios)
IOS_ID=$(flutter devices 2>/dev/null | grep "ios" | head -1 | awk -F'•' '{gsub(/^ +| +$/,"",$2); print $2}')
[[ -n "$IOS_ID" ]] && exec flutter run -d "$IOS_ID" "$@"
exec flutter run -d ios "$@"
