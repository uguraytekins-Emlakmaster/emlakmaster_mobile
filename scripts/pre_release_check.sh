#!/usr/bin/env bash
# Dağıtım öncesi: kimlik, analiz, test, startup regresyon, isteğe bağlı bundle.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKIP_BUILD="${SKIP_BUILD:-1}"
SKIP_BUNDLE="${SKIP_BUNDLE:-0}"

echo "=== Pre-release kontrol ==="

if [[ -x "$ROOT/scripts/shield/shield.sh" ]]; then
  "$ROOT/scripts/shield/shield.sh" --quiet
fi

flutter pub get

bash "$ROOT/scripts/verify_firebase_identity.sh"

flutter analyze --no-fatal-infos

flutter test

bash "$ROOT/scripts/verify_startup_perf.sh"

PROFILE_APP="$ROOT/build/macos/Build/Products/Profile/emlakmaster_mobile.app"
if [[ "$SKIP_BUNDLE" != "1" && -d "$PROFILE_APP" ]]; then
  bash "$ROOT/scripts/check_macos_bundle_size.sh"
else
  echo "(Bundle atlandı — profile .app yok veya SKIP_BUNDLE=1)"
fi

if [[ "$SKIP_BUILD" != "1" ]]; then
  echo "== macOS release build =="
  if [[ -x "$ROOT/scripts/ensure_macos_profile_signing.sh" ]]; then
    "$ROOT/scripts/ensure_macos_profile_signing.sh" || true
  fi
  flutter build macos --release
  RELEASE_APP="$ROOT/build/macos/Build/Products/Release/emlakmaster_mobile.app"
  if [[ -d "$RELEASE_APP" ]]; then
    du -sh "$RELEASE_APP"
    if [[ "${SKIP_PACKAGE:-}" != "1" && -x "$ROOT/scripts/package_macos_release.sh" ]]; then
      bash "$ROOT/scripts/package_macos_release.sh"
    fi
  fi
fi

echo ""
echo "Firestore rules (prod): scripts/deploy_firestore_rules.sh"
echo "Tam perf baseline: scripts/capture_startup_baseline_full.sh"
echo ""
echo "Pre-release kontrolleri tamamlandı."
echo "Dağıtım: docs/MACOS_RELEASE.md"
