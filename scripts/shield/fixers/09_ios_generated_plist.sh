#!/usr/bin/env bash
# iOS: GoogleService-Info.plist Runner'da referanslı mı kontrol et; eksikse uyar.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
[[ ! -d ios/Runner ]] && exit 0
# Firebase kullanıyorsa plist gerekir
if grep -q firebase_core pubspec.yaml 2>/dev/null; then
  if [[ ! -f ios/Runner/GoogleService-Info.plist ]]; then
    echo "shield: 09_ios_generated_plist — ios/Runner/GoogleService-Info.plist yok (Firebase kullanılıyor). Firebase Console'dan ekleyin." >&2
  fi
fi
exit 0
