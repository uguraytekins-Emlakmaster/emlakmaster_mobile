#!/usr/bin/env bash
# Profile .app boyutu üst sınırı (release öncesi kontrol).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MAX_MB="${MACOS_PROFILE_APP_MAX_MB:-200}"
APP="$ROOT/build/macos/Build/Products/Profile/emlakmaster_mobile.app"

if [[ ! -d "$APP" ]]; then
  echo "Profile .app yok — önce: flutter build macos --profile" >&2
  exit 1
fi

SIZE_MB="$(du -sm "$APP" | awk '{print $1}')"
echo "Profile app: ${SIZE_MB} MB (limit ${MAX_MB} MB)"
echo "Path: $APP"

if [[ "$SIZE_MB" -gt "$MAX_MB" ]]; then
  echo "HATA: bundle ${SIZE_MB} MB > ${MAX_MB} MB" >&2
  exit 1
fi

echo "OK: bundle boyutu sınır içinde."
