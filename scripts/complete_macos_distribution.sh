#!/usr/bin/env bash
# Developer ID + export + notarize (tam akış).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
  echo "Developer ID yok — CSR oluşturuluyor…"
  bash "$ROOT/scripts/create_developer_id_csr.sh"
  bash "$ROOT/scripts/wait_import_developer_id_cert.sh" "${WAIT_CERT_SEC:-300}" || {
    echo "" >&2
    echo "Sertifika gelmedi. Apple Developer Program üyeliği ve Admin rolü gerekir." >&2
    echo "Xcode hatası: Team does not have permission to create Developer ID profiles" >&2
    exit 1
  }
fi

bash "$ROOT/scripts/export_macos_developer_id.sh"
bash "$ROOT/scripts/package_macos_release.sh"

if [[ -n "${APPLE_APP_PASSWORD:-}" ]]; then
  if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    export NOTARIZE=1
    bash "$ROOT/scripts/package_macos_release.sh"
  elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    bash "$ROOT/scripts/setup_notary_credentials.sh"
    export NOTARIZE=1 NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-AC_NOTARY}"
    bash "$ROOT/scripts/package_macos_release.sh"
  fi
fi

bash "$ROOT/scripts/check_macos_distribution_ready.sh"
