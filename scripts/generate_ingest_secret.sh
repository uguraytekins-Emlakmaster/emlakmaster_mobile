#!/usr/bin/env bash
# INGEST_SECRET için güçlü rastgele değer üretir (Cloud Functions ortamına yapıştırın).
set -euo pipefail
if command -v openssl &>/dev/null; then
  openssl rand -hex 32
else
  node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
fi
