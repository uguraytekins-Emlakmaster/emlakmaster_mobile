#!/usr/bin/env bash
# Developer ID + Apple notarytool (ortam değişkenleri zorunlu).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DMG="${1:-}"
APP="$ROOT/build/macos/Build/Products/Release/emlakmaster_mobile.app"
BUNDLE_ID="com.uguraytekin.emlakmastermobile"

: "${APPLE_ID:?APPLE_ID gerekli (Apple ID e-posta)}"
: "${APPLE_APP_PASSWORD:?APPLE_APP_PASSWORD gerekli (app-specific password)}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID gerekli}"

SIGN_ID="${MACOS_SIGN_IDENTITY:-Developer ID Application}"

if [[ -z "$DMG" ]]; then
  echo "Kullanım: NOTARIZE=1 ./scripts/package_macos_release.sh" >&2
  echo "   veya: $0 dist/macos/emlakmaster_mobile-….dmg" >&2
  exit 1
fi

if [[ ! -d "$APP" ]]; then
  echo "Release .app yok." >&2
  exit 1
fi

echo "=== Developer ID imza + notarization ==="
echo "Identity: $SIGN_ID"

# Tüm iç bileşenleri imzala
/usr/bin/codesign --force --options runtime --timestamp \
  --sign "$SIGN_ID" \
  --deep "$APP"

/usr/bin/codesign --verify --deep --strict "$APP"

ZIP="$ROOT/dist/macos/notarize-submit.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "Notarytool gönderimi…"
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  xcrun notarytool submit "$ZIP" \
    --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
    --wait
else
  xcrun notarytool submit "$ZIP" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait
fi

xcrun stapler staple "$APP"
echo "Staple tamam."

# DMG yeniden oluştur (staple sonrası)
NOTARIZE=0 "$ROOT/scripts/package_macos_release.sh"
echo "Notarization tamamlandı."
