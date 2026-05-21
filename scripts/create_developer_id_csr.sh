#!/usr/bin/env bash
# Developer ID Application için CSR üretir ve Apple portalını açar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/macos/signing"
mkdir -p "$OUT"

KEY="$OUT/developer_id.key"
CSR="$OUT/developer_id.csr"

if [[ ! -f "$KEY" ]]; then
  openssl genrsa -out "$KEY" 2048 2>/dev/null
fi
openssl req -new -key "$KEY" -out "$CSR" -subj "/emailAddress=aytekinugi@gmail.com/CN=Emlak Master/C=TR" 2>/dev/null

echo "CSR: $CSR"
echo "Key: $KEY (gizli tutun, yedekleyin)"
echo ""
echo "Apple Developer → Certificates → + → Developer ID Application"
echo "→ Upload CSR → indirilen .cer dosyasına çift tık"
echo ""
open "$CSR" 2>/dev/null || true
open "https://developer.apple.com/account/resources/certificates/add" 2>/dev/null || true
