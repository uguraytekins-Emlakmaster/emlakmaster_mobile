#!/usr/bin/env bash
# Yerelde ingest (Playwright + Firestore). Kimlik: .service_account.json veya env.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INGEST="$ROOT/tools/github_listings_ingest"
cd "$INGEST"

if [[ -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.local
  set +a
fi

pip install -q -r requirements.txt
playwright install chromium
python ingest_sahibinden.py
