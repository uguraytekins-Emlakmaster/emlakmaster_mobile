#!/usr/bin/env bash
# Firestore güvenlik kurallarını emlak-master projesine yükler.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
exec firebase deploy --only firestore:rules --project emlak-master "$@"
