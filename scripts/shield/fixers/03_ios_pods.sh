#!/usr/bin/env bash
# iOS: Pods senkron; Podfile veya pubspec değiştiyse pod install.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
[[ ! -d ios ]] && exit 0
[[ ! -f ios/Podfile ]] && exit 0
# Generated.xcconfig yoksa önce Flutter tarafı
[[ ! -f ios/Flutter/Generated.xcconfig ]] && exit 0
if [[ ! -d ios/Pods ]] || [[ ios/Podfile -nt ios/Podfile.lock ]] 2>/dev/null; then
  echo "shield: 03_ios_pods — pod install çalıştırılıyor."
  (cd ios && pod install) || echo "shield: 03_ios_pods — pod install atlandı (manuel çalıştırın: cd ios && pod install)" >&2
fi
exit 0
