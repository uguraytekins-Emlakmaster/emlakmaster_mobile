#!/usr/bin/env bash
# Kabloyla bağlı iPhone: temiz derleme + pod + flutter run dener; imza hatasında Xcode açar.
# Apple hesabı / profil hatası: doc/IOS_TELEFON_YUKLEME.md
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DO_CLEAN=1
for arg in "$@"; do
  case "$arg" in
    --quick) DO_CLEAN=0 ;;
    --clean) DO_CLEAN=1 ;;
  esac
done

echo "=== EmlakMaster — iPhone kablo yükleme ==="

if [[ "$DO_CLEAN" -eq 1 ]]; then
  echo "→ flutter clean"
  flutter clean
fi

echo "→ flutter pub get"
flutter pub get

echo "→ pod install (ios)"
( cd ios && pod install )

echo ""
echo "Bağlı cihazlar:"
flutter devices

IOS_ID=""
while IFS= read -r line; do
  if echo "$line" | grep -qiE '\sios\s'; then
    IOS_ID=$(echo "$line" | awk -F'•' '{gsub(/^ +| +$/,"",$2); print $2}')
    break
  fi
done < <(flutter devices 2>/dev/null || true)

if [[ -z "$IOS_ID" ]]; then
  echo ""
  echo "iPhone listede yok. Kabloyu kontrol edin; Xcode → Window → Devices and Simulators."
  echo "Xcode workspace açılıyor — Product → Run ile de yükleyebilirsiniz."
  open ios/Runner.xcworkspace
  exit 1
fi

echo ""
echo "→ flutter run -d $IOS_ID (debug, kablolu)"
set +e
flutter run -d "$IOS_ID" --no-pub
RUN_EXIT=$?
set -e

if [[ "$RUN_EXIT" -eq 0 ]]; then
  echo "Tamamlandı."
  exit 0
fi

echo ""
echo "────────────────────────────────────────────────────────────"
echo "Terminalden imza/yükleme tamamlanamadı (çıkış kodu: $RUN_EXIT)."
echo "Sık görülen nedenler:"
echo "  • Xcode → Settings → Accounts: Apple ID yok veya oturum düşmüş"
echo "  • 'No Account for Team Q885JNUR54' → Accounts’tan aytekinugi@gmail.com ile giriş"
echo "  • Runner → Signing & Capabilities → Team seçili olsun"
echo ""
echo "Xcode açılıyor: Product → Clean Build Folder, sonra Product → Run (Cmd+R)."
echo "Ayrıntı: doc/IOS_TELEFON_YUKLEME.md"
echo "────────────────────────────────────────────────────────────"
open ios/Runner.xcworkspace
exit "$RUN_EXIT"
