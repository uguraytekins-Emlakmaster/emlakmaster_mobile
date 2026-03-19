#!/usr/bin/env bash
# Facebook Login için App ID ve Client Token'ı tek seferde tüm platformlara yazar.
# Kullanım:
#   ./scripts/configure_facebook_app.sh          → sırayla App ID ve Client Token sorar
#   ./scripts/configure_facebook_app.sh "ID" "TOKEN"
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Önce dosyadan dene (2 satır: App ID, Client Token)
CRED_FILE="$PROJECT_ROOT/scripts/facebook_credentials.txt"
if [ -z "$1" ] && [ -z "$FACEBOOK_APP_ID" ] && [ -f "$CRED_FILE" ]; then
  APP_ID=$(sed -n '1p' "$CRED_FILE" | tr -d '[:space:]')
  CLIENT_TOKEN=$(sed -n '2p' "$CRED_FILE" | tr -d '[:space:]')
fi
APP_ID="${1:-${FACEBOOK_APP_ID:-$APP_ID}}"
CLIENT_TOKEN="${2:-${FACEBOOK_CLIENT_TOKEN:-$CLIENT_TOKEN}}"
if [ -z "$APP_ID" ]; then
  echo ""
  echo "  Facebook Developer → Settings → Basic"
  echo "  App ID (sadece sayı, örn. 1234567890123456):"
  read -r APP_ID
  APP_ID=$(echo "$APP_ID" | tr -d '[:space:]')
fi
if [ -z "$CLIENT_TOKEN" ]; then
  echo ""
  echo "  Aynı sayfada Client token (uzun metin):"
  read -r CLIENT_TOKEN
  CLIENT_TOKEN=$(echo "$CLIENT_TOKEN" | tr -d '[:space:]')
fi
if [ -z "$APP_ID" ] || [ -z "$CLIENT_TOKEN" ]; then
  echo "Hata: App ID ve Client Token boş olamaz."
  exit 1
fi
echo ""
echo "  App ID: ${APP_ID:0:8}..."
echo "  Güncelleniyor..."
# URL scheme = fb + App ID
SCHEME="fb${APP_ID}"
ANDROID_RES="$PROJECT_ROOT/android/app/src/main/res/values/strings.xml"
ANDROID_GRADLE="$PROJECT_ROOT/android/app/build.gradle"
IOS_PLIST="$PROJECT_ROOT/ios/Runner/Info.plist"
# Android strings.xml
if [ -f "$ANDROID_RES" ]; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "s|<string name=\"facebook_app_id\"[^>]*>.*</string>|<string name=\"facebook_app_id\" translatable=\"false\">$APP_ID</string>|" "$ANDROID_RES"
    sed -i "s|<string name=\"facebook_client_token\"[^>]*>.*</string>|<string name=\"facebook_client_token\" translatable=\"false\">$CLIENT_TOKEN</string>|" "$ANDROID_RES"
    sed -i "s|<string name=\"facebook_login_protocol_scheme\"[^>]*>.*</string>|<string name=\"facebook_login_protocol_scheme\" translatable=\"false\">$SCHEME</string>|" "$ANDROID_RES"
  else
    sed -i '' "s|<string name=\"facebook_app_id\"[^>]*>.*</string>|<string name=\"facebook_app_id\" translatable=\"false\">$APP_ID</string>|" "$ANDROID_RES"
    sed -i '' "s|<string name=\"facebook_client_token\"[^>]*>.*</string>|<string name=\"facebook_client_token\" translatable=\"false\">$CLIENT_TOKEN</string>|" "$ANDROID_RES"
    sed -i '' "s|<string name=\"facebook_login_protocol_scheme\"[^>]*>.*</string>|<string name=\"facebook_login_protocol_scheme\" translatable=\"false\">$SCHEME</string>|" "$ANDROID_RES"
  fi
  echo "Güncellendi: $ANDROID_RES"
fi
# Android build.gradle manifestPlaceholders
if [ -f "$ANDROID_GRADLE" ]; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "s|facebookAppId: \"[^\"]*\"|facebookAppId: \"$APP_ID\"|" "$ANDROID_GRADLE"
  else
    sed -i '' "s|facebookAppId: \"[^\"]*\"|facebookAppId: \"$APP_ID\"|" "$ANDROID_GRADLE"
  fi
  echo "Güncellendi: $ANDROID_GRADLE"
fi
# iOS Info.plist (FacebookAppID / FacebookClientToken / fb... scheme satırlarını güncelle)
if [ -f "$IOS_PLIST" ]; then
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "/<key>FacebookAppID<\\/key>/{n;s/<string>.*<\\/string>/<string>$APP_ID<\\/string>/}" "$IOS_PLIST"
    sed -i "/<key>FacebookClientToken<\\/key>/{n;s/<string>.*<\\/string>/<string>$CLIENT_TOKEN<\\/string>/}" "$IOS_PLIST"
    sed -i "/<key>CFBundleURLSchemes<\\/key>/{n;n;s/<string>fb[^<]*<\\/string>/<string>$SCHEME<\\/string>/}" "$IOS_PLIST"
  else
    sed -i '' "/<key>FacebookAppID<\\/key>/{n;s/<string>.*<\\/string>/<string>$APP_ID<\\/string>/;}" "$IOS_PLIST"
    sed -i '' "/<key>FacebookClientToken<\\/key>/{n;s/<string>.*<\\/string>/<string>$CLIENT_TOKEN<\\/string>/;}" "$IOS_PLIST"
    # Facebook URL scheme: fb ile başlayan string (ikinci CFBundleURLSchemes grubunda)
    sed -i '' "s|<string>fb[0-9][0-9]*</string>|<string>$SCHEME</string>|" "$IOS_PLIST"
  fi
  echo "Güncellendi: $IOS_PLIST"
fi
echo ""
echo "  Tamam. Android + iOS yapılandırıldı."
echo "  Firebase Console'da Authentication → Sign-in method → Facebook'u açıp App ID + App Secret girdiysen uygulamayı çalıştır:"
echo "  flutter clean && flutter pub get && flutter run"
echo ""
