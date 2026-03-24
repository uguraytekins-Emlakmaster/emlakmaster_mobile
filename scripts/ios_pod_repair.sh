#!/usr/bin/env bash
# iOS: Podfile.lock ↔ Pods senkronu + isteğe bağlı CocoaPods önbellek onarımı.
#
# Kullanım:
#   scripts/ios_pod_repair.sh
#   scripts/ios_pod_repair.sh --repo-update     # trunk CDN tam yenileme (daha uzun)
#   scripts/ios_pod_repair.sh --clean-cache     # JSON::ParserError / bozuk gRPC podspec
#   scripts/ios_pod_repair.sh --clean-cache --repo-update
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

REPO_UPDATE=0
CLEAN_CACHE=0
for a in "$@"; do
  case "$a" in
    --repo-update) REPO_UPDATE=1 ;;
    --clean-cache) CLEAN_CACHE=1 ;;
  esac
done

echo "ios_pod_repair: flutter pub get"
flutter pub get

cd ios

if [[ "$CLEAN_CACHE" -eq 1 ]]; then
  echo "ios_pod_repair: CocoaPods önbelleği temizleniyor (gRPC-Core.podspec.json vb.)..."
  rm -rf "${HOME}/Library/Caches/CocoaPods" 2>/dev/null || true
  pod cache clean --all 2>/dev/null || true
  # Cursor agent: kesik JSON bırakan sandbox CDN klasörü
  while IFS= read -r -d '' d; do
    echo "ios_pod_repair: bozuk trunk gRPC cache siliniyor: $d"
    rm -rf "$d"
  done < <(find /var/folders -type d \( -path '*/cursor-sandbox-cache/*/cocoapods/repos/trunk/Specs/*/*/*/gRPC-Core' -o -path '*/cursor-sandbox-cache/*/cocoapods/repos/trunk/Specs/*/*/gRPC-Core' \) -print0 2>/dev/null || true)
  # trunk tam yenileme sadece --repo-update ile (yavaş)
  if [[ "$REPO_UPDATE" -eq 1 ]]; then
    echo "ios_pod_repair: pod repo update"
    pod repo update 2>/dev/null || true
  fi
fi

if [[ "$REPO_UPDATE" -eq 1 ]]; then
  echo "ios_pod_repair: pod install --repo-update"
  pod install --repo-update
else
  echo "ios_pod_repair: pod install (hızlı; tam repo için: --repo-update)"
  pod install
fi

echo "ios_pod_repair: tamam. Xcode: ios/Runner.xcworkspace (⌘B)"
