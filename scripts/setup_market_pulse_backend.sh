#!/usr/bin/env bash
# Market Pulse backend: Functions deploy + (isteğe bağlı) Firestore intelligence_pipeline seed.
# Gereksinim: firebase-tools (npm i -g firebase-tools), Blaze plan, firebase login.
# Seed için: GOOGLE_APPLICATION_CREDENTIALS veya gcloud application-default login.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "→ functions: npm install"
(cd "$ROOT/functions" && npm install)

echo "→ firebase deploy --only functions --project emlak-master"
firebase deploy --only functions --project emlak-master

echo ""
echo "→ İsteğe bağlı: intelligence_pipeline seed (CLIENT_SEED_INTELLIGENCE=false varsayılan)"
if [[ "${SKIP_SEED:-}" == "1" ]]; then
  echo "  SKIP_SEED=1 — seed atlandı."
  exit 0
fi

if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] || command -v gcloud &>/dev/null; then
  (cd "$ROOT/functions" && node tools/seed_intelligence_pipeline.js) && echo "✓ Seed tamam." || {
    echo "⚠ Seed başarısız (yetki veya ADC yok). Manuel: Console → Firestore → app_settings → intelligence_pipeline"
    exit 0
  }
else
  echo "⚠ GOOGLE_APPLICATION_CREDENTIALS tanımlı değil; seed atlandı."
  echo "  Sonra çalıştırın: export GOOGLE_APPLICATION_CREDENTIALS=... && $ROOT/scripts/seed_intelligence_pipeline_only.sh"
fi
