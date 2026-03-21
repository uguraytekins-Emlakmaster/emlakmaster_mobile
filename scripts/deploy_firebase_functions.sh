#!/usr/bin/env bash
# Market Pulse: Cloud Functions (fetchListingsNow, scheduledFetchListings) → Firebase
# Gereksinim: firebase-tools, npm, proje kökünde .firebaserc
# ÜRETİM: Firebase projesi Blaze (pay-as-you-go) olmalı — Spark planda deploy edilemez.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/functions"
npm install
cd "$ROOT"
echo "→ firebase deploy --only functions --project emlak-master"
if firebase deploy --only functions --project emlak-master; then
  echo "✓ Functions deploy tamam."
else
  ec=$?
  echo ""
  echo "Deploy başarısız (çıkış: $ec). Sık nedenler:"
  echo "  • Proje Spark planda: Blaze’e yükselt → https://console.firebase.google.com/project/emlak-master/usage/details"
  echo "  • firebase login ile oturum açın."
  echo "  • Yerel test için: scripts/run_functions_emulator.sh + USE_FUNCTIONS_EMULATOR=true"
  exit "$ec"
fi
