#!/usr/bin/env bash
# Release .app → DMG; isteğe bağlı notarization (Developer ID gerekir).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="emlakmaster_mobile"
BUNDLE_ID="com.uguraytekin.emlakmastermobile"
RELEASE_APP="$ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"
DIST_DIR="$ROOT/dist/macos"
VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
STAMP="$(date +%Y%m%d)"
DMG_NAME="${APP_NAME}-${VERSION}-${STAMP}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
STAGING="$DIST_DIR/staging"

echo "=== macOS release paketleme ==="

if [[ ! -d "$RELEASE_APP" ]]; then
  echo "Release .app yok. Önce: flutter build macos --release" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$RELEASE_APP" "$STAGING/"

echo "İmza doğrulama…"
codesign --verify --deep --strict "$STAGING/${APP_NAME}.app" 2>/dev/null || {
  echo "UYARI: codesign doğrulama başarısız." >&2
}

AUTH="$(codesign -dvv "$STAGING/${APP_NAME}.app" 2>&1 | awk -F= '/^Authority=/{print $2; exit}')"
echo "İmza: ${AUTH:-bilinmiyor}"

if echo "$AUTH" | grep -q "Apple Development"; then
  echo ""
  echo "NOT: 'Apple Development' imzası yalnızca geliştirme cihazları içindir."
  echo "     Başka Mac’lere dağıtım + notarization için Xcode’da"
  echo "     'Developer ID Application' sertifikası ile yeniden imzalayın."
  echo "     Ayrıntı: docs/MACOS_RELEASE.md"
  echo ""
fi

rm -f "$DMG_PATH"
hdiutil create \
  -volname "Emlak Master" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING"
du -sh "$RELEASE_APP" "$DMG_PATH"

echo ""
echo "DMG: $DMG_PATH"
echo "Yerel test: open \"$RELEASE_APP\""

if [[ "${NOTARIZE:-}" == "1" ]]; then
  exec "$ROOT/scripts/notarize_macos_release.sh" "$DMG_PATH"
fi
