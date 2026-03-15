#!/usr/bin/env bash
# Flutter proje bütünlüğü: pub get, gerekirse clean, .dart_tool ve lock dosyası.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"

run_pub_get() {
  if flutter pub get --no-offline 2>/dev/null; then
    return 0
  fi
  echo "shield: 01_flutter_health — pub get başarısız, clean deneniyor..."
  flutter clean 2>/dev/null || true
  flutter pub get
}

if [[ ! -f pubspec.lock ]] || [[ ! -d .dart_tool ]]; then
  echo "shield: 01_flutter_health — pubspec.lock veya .dart_tool eksik, pub get çalıştırılıyor."
  run_pub_get
fi
# Generated.xcconfig (iOS) Flutter build için gerekli
if [[ -d ios ]] && [[ ! -f ios/Flutter/Generated.xcconfig ]]; then
  echo "shield: 01_flutter_health — ios/Flutter/Generated.xcconfig yok, pub get çalıştırılıyor."
  run_pub_get
fi
exit 0
