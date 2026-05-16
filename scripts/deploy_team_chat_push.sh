#!/usr/bin/env bash
# Ekip sohbeti FCM Cloud Function — billing + App Engine önkoşullarını kontrol eder, deploy eder.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="${FIREBASE_PROJECT:-emlak-master}"
REGION="${FUNCTIONS_REGION:-europe-west1}"

cd "$ROOT"

echo "==> Proje: $PROJECT (bölge: $REGION)"

if ! command -v gcloud >/dev/null 2>&1 || ! command -v firebase >/dev/null 2>&1; then
  echo "Hata: gcloud ve firebase CLI gerekli." >&2
  exit 1
fi

BILLING_JSON="$(gcloud billing projects describe "$PROJECT" --format=json 2>/dev/null || true)"
if [[ -z "$BILLING_JSON" ]]; then
  echo "Hata: Proje faturalandırması okunamadı. gcloud auth login" >&2
  exit 1
fi

BILLING_ACCOUNT="$(python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('billingAccountName','').split('/')[-1])" <<<"$BILLING_JSON")"
BILLING_ENABLED="$(python3 -c "import json,sys; d=json.load(sys.stdin); print('true' if d.get('billingEnabled') else 'false')" <<<"$BILLING_JSON")"

if [[ -z "$BILLING_ACCOUNT" || "$BILLING_ENABLED" != "true" ]]; then
  echo "Hata: $PROJECT için faturalandırma bağlı değil." >&2
  echo "  https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT" >&2
  exit 1
fi

ACCOUNT_OPEN="$(gcloud billing accounts describe "$BILLING_ACCOUNT" --format='value(open)' 2>/dev/null || echo "false")"
if [[ "$ACCOUNT_OPEN" != "True" && "$ACCOUNT_OPEN" != "true" ]]; then
  echo "Hata: Faturalandırma hesabı kapalı: $BILLING_ACCOUNT" >&2
  echo "  Google Cloud Console → Faturalandırma → hesabı yeniden açın veya ödeme yöntemi ekleyin:" >&2
  echo "  https://console.cloud.google.com/billing/$BILLING_ACCOUNT" >&2
  echo "  Firebase Blaze: https://console.firebase.google.com/project/$PROJECT/usage/details" >&2
  exit 1
fi

if ! gcloud app describe --project="$PROJECT" >/dev/null 2>&1; then
  echo "==> App Engine yok; $REGION ile oluşturuluyor (bir kez)..."
  gcloud app create --region="$REGION" --project="$PROJECT"
fi

echo "==> Cloud Function deploy: onTeamChatMessageCreated"
firebase deploy --only functions:onTeamChatMessageCreated --project "$PROJECT"
echo "==> Tamam."
