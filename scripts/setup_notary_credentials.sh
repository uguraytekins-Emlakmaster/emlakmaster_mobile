#!/usr/bin/env bash
# Notarytool anahtar zinciri profili (bir kez).
set -euo pipefail

: "${APPLE_ID:?APPLE_ID gerekli}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID gerekli}"
: "${APPLE_APP_PASSWORD:?APPLE_APP_PASSWORD gerekli (app-specific password)}"

PROFILE="${NOTARY_KEYCHAIN_PROFILE:-AC_NOTARY}"

echo "Notary profili: $PROFILE"
xcrun notarytool store-credentials "$PROFILE" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD"

echo "Kaydedildi. Notarize: NOTARY_KEYCHAIN_PROFILE=$PROFILE NOTARIZE=1 ./scripts/package_macos_release.sh"
