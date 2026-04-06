#!/usr/bin/env bash
# Firebase Storage: API'leri açar, ardından kuralları deploy etmeyi dener.
# İlk kova oluşturma hâlâ çoğu projede Console → Depolama → "Başlayın" gerektirir;
# bu script API tarafını hazırlar ve deploy dener.
set -euo pipefail
PROJECT_ID="${1:-emlak-master}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "==> Proje: $PROJECT_ID"
echo "==> Dizin: $ROOT"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud yok. Kurulum: brew install --cask google-cloud-sdk"
  exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
  echo ""
  echo "Önce Google hesabınla giriş yap (tarayıcı açılır):"
  echo "  gcloud auth login"
  echo ""
  exit 2
fi

gcloud config set project "$PROJECT_ID"

echo "==> Gerekli API'ler etkinleştiriliyor..."
gcloud services enable firebasestorage.googleapis.com --project="$PROJECT_ID"
gcloud services enable storage.googleapis.com --project="$PROJECT_ID"

echo "==> firebase deploy --only storage deneniyor..."
cd "$ROOT"
if command -v firebase >/dev/null 2>&1; then
  firebase deploy --only storage --non-interactive || {
    echo ""
    echo "-------------------------------------------------------------------"
    echo "Deploy başarısız: Firebase Storage henüz bu projede 'Başlatılmamış' olabilir."
    echo "Tarayıcıda (giriş yapmış hesabınla) şunu açıp sihirbazı tamamla:"
    echo "  https://console.firebase.google.com/project/${PROJECT_ID}/storage"
    echo "  → Depolama → Başlayın → kova + kurallar adımları"
    echo "Sonra tekrar:"
    echo "  cd $ROOT && firebase deploy --only storage"
    echo "-------------------------------------------------------------------"
    exit 3
  }
  echo "==> Tamam: storage.rules deploy edildi."
else
  echo "firebase CLI bulunamadı: npm i -g firebase-tools"
  exit 4
fi
