#!/usr/bin/env bash
# Firebase servis hesabı JSON'unu GitHub Actions secret olarak yükler.
# Önkoşul: brew install gh && gh auth login
#
# Kullanım:
#   ./scripts/github_listings_push_secret.sh ~/Downloads/firebase-adminsdk-xxxxx.json
# veya:
#   export FIREBASE_SERVICE_ACCOUNT_FILE=~/path/to.json
#   ./scripts/github_listings_push_secret.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FILE="${1:-${FIREBASE_SERVICE_ACCOUNT_FILE:-}}"
# ~/Downloads/... bazen genişlemez; $HOME ile düzelt
if [[ -n "$FILE" ]]; then
  FILE="${FILE/#\~/$HOME}"
fi

if [[ -z "$FILE" ]]; then
  echo "Kullanım:"
  echo "  bash scripts/github_listings_push_secret.sh /tam/yol/firebase-adminsdk-xxxxx.json"
  echo "veya (emlakmaster_mobile kökündeyken):"
  echo "  bash push_firebase_secret_to_github.sh ~/Downloads/firebase-adminsdk-xxxxx.json"
  echo "veya: export FIREBASE_SERVICE_ACCOUNT_FILE=... && bash scripts/github_listings_push_secret.sh"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Dosya bulunamadı: $FILE"
  echo "İpucu: Finder'da JSON'a sağ tık → Basılı tutarken Option → 'Yol adı olarak kopyala' → buraya yapıştır."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Hata: Bu klasör bir git deposu değil (gh secret bu repoya yazar)."
  echo "Şu klasöre geç: .../emlakmaster_mobile (içinde .git olmalı)"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "GitHub CLI (gh) yok. Kur: brew install gh && gh auth login"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Önce: gh auth login"
  exit 1
fi

echo "Secret yükleniyor: FIREBASE_SERVICE_ACCOUNT_JSON (bu repo)..."
echo "Çalışma dizini: $ROOT"
if ! gh secret set FIREBASE_SERVICE_ACCOUNT_JSON <"$FILE"; then
  echo ""
  echo "Manuel:"
  echo "  cd \"$ROOT\""
  echo "  gh secret set FIREBASE_SERVICE_ACCOUNT_JSON < \"$FILE\""
  exit 1
fi
echo "Tamam. GitHub → Actions → «External listings ingest» → Run workflow ile dene."
