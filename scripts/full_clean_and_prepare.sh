#!/usr/bin/env bash
# Tam temiz kurulum: clean, pub get, shield, iOS pod install. Çalıştır: ./scripts/full_clean_and_prepare.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
echo "1/4 flutter clean..."
flutter clean
echo "2/4 flutter pub get + shield..."
flutter pub get
"$SCRIPT_DIR/shield/shield.sh" --quiet
echo "3/4 iOS plugin sırası ve pod install..."
"$SCRIPT_DIR/fix_ios_plugin_order.sh" 2>/dev/null || true
if [[ -d ios ]] && [[ -f ios/Podfile ]]; then
  (cd ios && pod install)
fi
echo "4/4 Bitti. Çalıştırmak için: flutter run"
exit 0
