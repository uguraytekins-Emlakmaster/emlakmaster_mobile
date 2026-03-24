#!/usr/bin/env bash
# Sadece app_settings/intelligence_pipeline yazar (Functions deploy etmez).
# Örnek:
#   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/emlak-master-sa.json"
#   ./scripts/seed_intelligence_pipeline_only.sh
#
# İstemci demo açık kalsın (geliştirme):
#   CLIENT_SEED_INTELLIGENCE=true ./scripts/seed_intelligence_pipeline_only.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
(cd "$ROOT/functions" && npm install --silent && node tools/seed_intelligence_pipeline.js)
