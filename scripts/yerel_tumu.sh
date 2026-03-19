#!/usr/bin/env bash
# Yerelde tüm otomatik kontroller: shield → pub get → analyze → test.
# Kullanım: ./scripts/yerel_tumu.sh
# İsteğe bağlı macOS derlemesi: YEREL_MACOS_BUILD=1 ./scripts/yerel_tumu.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> shield"
./scripts/shield/shield.sh

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze lib"
flutter analyze lib

echo "==> flutter test"
flutter test

if [[ "${YEREL_MACOS_BUILD:-}" == "1" ]]; then
  echo "==> flutter build macos --debug"
  flutter build macos --debug
fi

echo ""
echo "Tamam: shield + analyze + test$( [[ "${YEREL_MACOS_BUILD:-}" == "1" ]] && echo ' + macOS build' )."
echo "Android SHA-1 (Firebase): Java yüklüyken: cd android && ./gradlew :app:signingReport"
echo " veya: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
