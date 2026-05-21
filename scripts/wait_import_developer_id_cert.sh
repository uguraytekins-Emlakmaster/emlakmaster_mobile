#!/usr/bin/env bash
# ~/Downloads içindeki yeni .cer dosyasını içe aktarır; Developer ID gelene kadar bekler.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAX_SEC="${1:-180}"
INTERVAL=5
elapsed=0

echo "Developer ID sertifikası bekleniyor (${MAX_SEC}s)…"
echo "Portalda CSR yükleyip .cer indirin."

before="$(ls -1t ~/Downloads/*.cer 2>/dev/null | head -1 || true)"

while [[ "$elapsed" -lt "$MAX_SEC" ]]; do
  latest="$(ls -1t ~/Downloads/*.cer 2>/dev/null | head -1 || true)"
  if [[ -n "$latest" && "$latest" != "$before" ]]; then
    echo "Bulundu: $latest"
    security import "$latest" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null \
      || security import "$latest" -k ~/Library/Keychains/login.keychain -T /usr/bin/codesign 2>/dev/null \
      || open "$latest"
    sleep 2
  fi

  if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    echo "Developer ID Application yüklendi."
    security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID"
    exit 0
  fi

  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
  echo "  … ${elapsed}s"
done

echo "Zaman aşımı. ./scripts/create_developer_id_csr.sh ile CSR adımlarını tamamlayın." >&2
exit 1
