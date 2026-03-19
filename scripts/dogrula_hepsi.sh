#!/usr/bin/env bash
# Tam doğrulama: analyze + test + macOS debug build + Firestore rules derlemesi.
# CI veya sürüm öncesi: ./scripts/dogrula_hepsi.sh
# Sadece hızlı: DOGRULA_SKIP_MACOS=1 ./scripts/dogrula_hepsi.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze (tüm proje; info seviyesi fatal değil)"
flutter analyze --no-fatal-infos --no-fatal-warnings

echo "==> flutter test"
flutter test

if [[ "${DOGRULA_SKIP_MACOS:-}" == "1" ]]; then
  echo "==> macOS build atlandı (DOGRULA_SKIP_MACOS=1)"
else
  echo "==> flutter build macos --debug"
  flutter build macos --debug
fi

if command -v firebase >/dev/null 2>&1; then
  echo "==> firestore.rules derleme (dry-run)"
  firebase deploy --only firestore:rules --project emlak-master --dry-run
else
  echo "==> firebase CLI yok; firestore.rules atlandı"
fi

echo ""
echo "dogrula_hepsi: TAMAM."
