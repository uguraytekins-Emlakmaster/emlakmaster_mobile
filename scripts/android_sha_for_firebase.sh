#!/usr/bin/env bash
# Debug keystore SHA-1 / SHA-256 — Firebase Console > Proje ayarları > Android uygulamanıza yapıştırın.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$ROOT/scripts/env_homebrew_java.sh" ]] && source "$ROOT/scripts/env_homebrew_java.sh"

if command -v keytool >/dev/null 2>&1; then
  echo "=== Debug keystore (varsayılan) ==="
  keytool -list -v -keystore "${HOME}/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E "SHA1:|SHA256:" || true
  exit 0
fi

if [[ -x "${ANDROID_HOME:-}/jre/bin/keytool" ]]; then
  "${ANDROID_HOME}/jre/bin/keytool" -list -v -keystore "${HOME}/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E "SHA1:|SHA256:" || true
  exit 0
fi

if [[ -f "$ROOT/android/gradlew" ]]; then
  if command -v java >/dev/null 2>&1; then
    (cd "$ROOT/android" && ./gradlew :app:signingReport 2>/dev/null | grep -E "SHA1|SHA-1|Variant: debug" | head -30) || true
    exit 0
  fi
fi

echo "Java/keytool bulunamadı. Android Studio JDK veya Temurin JDK kurun; sonra tekrar çalıştırın."
exit 1
