#!/usr/bin/env bash
# Google OAuth 401 düzeltmesi: Console sayfasını açar, kopyalamanız gereken değerleri yazar.
# Çalıştırın: ./scripts/open_google_oauth_setup.sh
# Tarayıcıda giriş yapıp aşağıdaki değerlerle iOS + Android OAuth client oluşturun.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ID="emlak-master"
CREDENTIALS_URL="https://console.cloud.google.com/apis/credentials?project=${PROJECT_ID}"

echo ""
echo "=== Google OAuth kurulumu (401 invalid_client düzeltmesi) ==="
echo ""
echo "Tarayıcı açılıyor: Credentials sayfası (proje: $PROJECT_ID)"
echo "Giriş yapın ve aşağıdaki adımları uygulayın."
echo ""

# macOS
if command -v open >/dev/null 2>&1; then
  open "$CREDENTIALS_URL"
# Linux
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$CREDENTIALS_URL"
fi

echo "--- 1) iOS OAuth client ---"
echo "  CREATE CREDENTIALS → OAuth client ID"
echo "  Application type: iOS"
echo "  Name: EmlakMaster iOS"
echo "  Bundle ID (birebir yapıştırın):"
echo "    com.example.emlakmasterMobile"
echo "  Create → çıkan iOS URL scheme'ı not alın; Info.plist'teki CFBundleURLSchemes ile aynı olmalı (zaten com.googleusercontent.apps.572835725773-93531b623c67ce9392c484 ise değiştirmeyin)."
echo ""
echo "--- 2) Android OAuth client ---"
echo "  CREATE CREDENTIALS → OAuth client ID"
echo "  Application type: Android"
echo "  Name: EmlakMaster Android"
echo "  Package name (birebir yapıştırın):"
echo "    com.example.emlakmaster_mobile"
echo "  SHA-1: Aşağıda çıktı varsa onu yapıştırın; yoksa Android Studio → Gradle → android → signingReport çalıştırıp SHA1 satırını alın."
echo ""

# SHA-1 (Gradle ile; Java yoksa Android Studio → Gradle → signingReport)
if [[ -d "$PROJECT_ROOT/android" ]]; then
  SHA1=$(cd "$PROJECT_ROOT/android" && ./gradlew signingReport 2>/dev/null | grep -E "SHA1:|SHA-1" | head -1)
  if [[ -n "$SHA1" ]]; then
    echo "  Debug SHA-1: $SHA1"
  else
    echo "  Debug SHA-1: (Java gerekir — Android Studio'da Gradle → signingReport çalıştırın)"
  fi
fi

echo ""
echo "--- 3) Firebase Console ---"
echo "  https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
echo "  Google → Enabled olduğundan emin olun."
echo ""
echo "Bitti. Uygulamayı yeniden derleyip Google ile girişi deneyin."
echo ""
