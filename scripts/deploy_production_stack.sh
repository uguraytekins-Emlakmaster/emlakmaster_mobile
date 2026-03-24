#!/usr/bin/env bash
# Tek komut: Functions + Firestore kuralları + indeksler; isteğe bağlı Storage kuralları.
# Önkoşul: firebase-tools, .firebaserc, Blaze (Functions için).
#
# Kullanım:
#   bash scripts/deploy_production_stack.sh
#   bash scripts/deploy_production_stack.sh --no-storage   # Storage Console'da henüz açılmadıysa
#
# Storage hatası alırsanız: https://console.firebase.google.com/project/emlak-master/storage
# → "Get Started" ile bucket oluşturun; sonra bu script'i --no-storage OLMADAN tekrar çalıştırın.
#
# Not: Sadece Functions: scripts/deploy_firebase_functions.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/functions"
npm install
cd "$ROOT"

INCLUDE_STORAGE=1
for a in "$@"; do
  case "$a" in
    --no-storage) INCLUDE_STORAGE=0 ;;
  esac
done

if [[ "$INCLUDE_STORAGE" -eq 1 ]]; then
  TARGET="functions,firestore:rules,firestore:indexes,storage"
else
  TARGET="functions,firestore:rules,firestore:indexes"
fi

echo "→ firebase deploy --only $TARGET"
firebase deploy --only "$TARGET"
echo "✓ production stack deploy tamam."
if [[ "$INCLUDE_STORAGE" -eq 0 ]]; then
  echo ""
  echo "ℹ Storage kuralları atlandı. Dosya import (Storage) için önce Console'da Storage'ı açıp sonra tekrar:"
  echo "  bash scripts/deploy_production_stack.sh"
fi
