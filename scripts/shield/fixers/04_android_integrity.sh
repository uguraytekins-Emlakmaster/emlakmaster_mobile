#!/usr/bin/env bash
# Android: Kritik dosyalar ve gradle wrapper var mı; yoksa uyar.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
[[ ! -d android ]] && exit 0
MISSING=""
[[ ! -f android/app/build.gradle ]] && MISSING="$MISSING android/app/build.gradle"
[[ ! -f android/build.gradle ]] && MISSING="$MISSING android/build.gradle"
[[ ! -f android/settings.gradle ]] && MISSING="$MISSING android/settings.gradle"
[[ ! -x android/gradlew ]] && [[ -f android/gradlew ]] && chmod +x android/gradlew && echo "shield: 04_android_integrity — gradlew +x yapıldı."
if [[ -n "$MISSING" ]]; then
  echo "shield: 04_android_integrity — Eksik dosya (manuel kontrol):$MISSING" >&2
fi
exit 0
