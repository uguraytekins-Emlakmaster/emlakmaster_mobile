#!/usr/bin/env bash
# Dış dağıtım için eksikleri listeler (Developer ID + notarization).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_APP="$ROOT/build/macos/Build/Products/Release/emlakmaster_mobile.app"
DMG_GLOB="$ROOT/dist/macos/emlakmaster_mobile-*.dmg"

ok=0
warn=0
fail=0

_pass() { echo "  ✓ $1"; ok=$((ok + 1)); }
_warn() { echo "  ! $1"; warn=$((warn + 1)); }
_fail() { echo "  ✗ $1"; fail=$((fail + 1)); }

echo "=== macOS dağıtım hazırlığı ==="
echo ""

if [[ -d "$RELEASE_APP" ]]; then
  _pass "Release .app mevcut"
  du -sh "$RELEASE_APP" | sed 's/^/      /'
else
  _fail "Release .app yok → flutter build macos --release"
fi

if compgen -G "$DMG_GLOB" > /dev/null; then
  latest_dmg="$(ls -1t $DMG_GLOB 2>/dev/null | head -1)"
  _pass "DMG mevcut (${latest_dmg##*/})"
else
  _warn "DMG yok → ./scripts/package_macos_release.sh"
fi

if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application" || false; then
  _pass "Developer ID Application sertifikası yüklü"
else
  _fail "Developer ID Application yok (Apple Developer → Certificates)"
fi

if [[ -d "$RELEASE_APP" ]]; then
  AUTH="$(codesign -dvv "$RELEASE_APP" 2>&1 | awk -F= '/^Authority=/{print $2; exit}')"
  if echo "$AUTH" | grep -q "Developer ID Application"; then
    _pass "Uygulama Developer ID ile imzalı"
  elif echo "$AUTH" | grep -q "Apple Development"; then
    _warn "İmza: Apple Development (yalnızca geliştirme / kayıtlı cihaz)"
  else
    _warn "İmza: ${AUTH:-bilinmiyor}"
  fi

  if spctl -a -vv "$RELEASE_APP" 2>&1 | grep -q "accepted" || false; then
    _pass "Gatekeeper: accepted"
  else
    _warn "Gatekeeper: reddedildi veya notarize edilmedi"
  fi
fi

if [[ -n "${APPLE_APP_PASSWORD:-}" && -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  _pass "Notarization ortam değişkenleri tanımlı"
else
  _warn "Notarization için APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD gerekli"
fi

echo ""
echo "Özet: $ok geçti, $warn uyarı, $fail eksik"
echo "Rehber: docs/MACOS_RELEASE.md"

if [[ "$fail" -gt 0 ]]; then
  echo ""
  echo "Sıradaki adım: Apple Developer hesabında Developer ID Application oluşturun,"
  echo "Xcode’da Release imzasını güncelleyin, ardından:"
  echo "  flutter build macos --release"
  echo "  NOTARIZE=1 ./scripts/package_macos_release.sh"
  exit 1
fi

exit 0
