#!/usr/bin/env bash
# Repoda yapılabilecek HER şey: bağımlılık, test, .env.local şablonu, (varsa) ingest + (varsa) gh secret.
# Firebase JSON indirmek ve gh auth login — yine senin hesabında.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INGEST="$ROOT/tools/github_listings_ingest"
cd "$ROOT"

if [[ ! -f "$INGEST/ingest_sahibinden.py" ]]; then
  echo "Hata: emlakmaster_mobile kökünde değilsiniz veya yol bozuk."
  echo "Şöyle çalıştırın:"
  echo "  cd \"$ROOT\""
  echo "  bash scripts/listings_ingest_do_everything.sh"
  exit 1
fi

PY="${PYTHON:-}"
if [[ -z "$PY" ]]; then
  if command -v python3 &>/dev/null; then PY=python3
  elif command -v python &>/dev/null; then PY=python
  else echo "python3 bulunamadı."; exit 1; fi
fi
PIP="${PIP:-}"
if [[ -z "$PIP" ]]; then
  if command -v pip3 &>/dev/null; then PIP=pip3
  elif command -v pip &>/dev/null; then PIP=pip
  else PIP="$PY -m pip"; fi
fi

echo "== [1/5] Python ingest araçları — pip + pytest ($PY) =="
cd "$INGEST"
$PIP install -q -r requirements-dev.txt
$PY -m pytest tests/ -v --tb=short
echo "Pytest OK."

echo "== [2/5] Playwright Chromium (yerel ingest için) =="
$PY -m playwright install chromium
echo "Playwright OK."

echo "== [3/5] .env.local şablonu =="
if [[ ! -f "$INGEST/.env.local" ]]; then
  cp "$INGEST/env.local.example" "$INGEST/.env.local"
  echo "Oluşturuldu: tools/github_listings_ingest/.env.local (değerleri düzenle)"
else
  echo ".env.local zaten var, atlandı."
fi

echo "== [4/5] Firebase .service_account.json =="
SA="$INGEST/.service_account.json"
if [[ -f "$SA" ]]; then
  echo "Kimlik bulundu — yerel ingest çalıştırılıyor..."
  set -a
  # shellcheck disable=SC1091
  source "$INGEST/.env.local" 2>/dev/null || true
  set +a
  $PY ingest_sahibinden.py && echo "Ingest tamam." || echo "Ingest hata (ağ/Firestore) — yine de devam."
else
  echo "YOK: $SA"
  echo "  → Firebase Console'dan JSON indir, bu yola kopyala: .service_account.json"
fi

echo "== [5/5] GitHub CLI secret (isteğe bağlı) =="
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  if [[ -f "$SA" ]]; then
    if [[ -t 0 ]]; then
      read -r -p "FIREBASE_SERVICE_ACCOUNT_JSON secret'ını GitHub'a yükle? [y/N] " a
      if [[ "${a:-}" =~ ^[yY]$ ]]; then
        "$ROOT/scripts/github_listings_push_secret.sh" "$SA" || true
      else
        echo "Atlandı. İstersen: ./scripts/github_listings_push_secret.sh $SA"
      fi
    else
      echo "Non-interactive: ./scripts/github_listings_push_secret.sh $SA"
    fi
  else
    echo "gh girişli ama .service_account.json yok — secret atlandı."
  fi
else
  echo "gh yok veya giriş yok — atlandı. Kur: brew install gh && gh auth login"
fi

echo ""
echo "Bitti. Kalan tek insan adımı: Firebase'den JSON indirip .service_account.json yapmak (ve isteğe gh login)."
