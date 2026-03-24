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

# Xcode: "The sandbox is not in sync with the Podfile.lock" — Podfile.lock ile Pods/Manifest.lock aynı olmalı.
need_pod=0
[[ ! -d ios/Pods ]] && need_pod=1
[[ ! -f ios/Pods/Manifest.lock ]] && need_pod=1
if [[ -f ios/Podfile.lock && -f ios/Pods/Manifest.lock ]]; then
  if ! cmp -s ios/Podfile.lock ios/Pods/Manifest.lock 2>/dev/null; then
    need_pod=1
  fi
fi
[[ ios/Podfile -nt ios/Podfile.lock ]] 2>/dev/null && need_pod=1

if [[ $need_pod -eq 1 ]]; then
  echo "shield: 03_ios_pods — pod install çalıştırılıyor."
  (cd ios && pod install) || echo "shield: 03_ios_pods — pod install atlandı (manuel: cd ios && pod install)" >&2
fi
exit 0
