#!/usr/bin/env bash
# Shield + Android emülatör/cihazda çalıştır. Emülatör yoksa otomatik başlatır.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
"$SCRIPT_DIR/shield/shield.sh" --quiet 2>/dev/null || true
if ! flutter devices 2>/dev/null | grep -qi "android"; then
  echo "Android cihaz yok, emülatör başlatılıyor (açılması 1-2 dk sürebilir)..."
  flutter emulators --launch Medium_Phone_API_36.1 2>/dev/null || true
  echo "Emülatör açıldıktan sonra bu scripti tekrar çalıştırın: scripts/run_android.sh"
  exit 0
fi
exec flutter run -d android "$@"
