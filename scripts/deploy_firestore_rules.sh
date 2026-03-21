#!/usr/bin/env bash
# Market Pulse istemci yazımı için güncel firestore.rules (Spark planda ücretsiz deploy edilir).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
exec firebase deploy --only firestore:rules --project emlak-master
