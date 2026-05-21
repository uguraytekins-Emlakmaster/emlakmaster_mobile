#!/usr/bin/env bash
# Tam profile baseline: imza → soğuk açılış → giriş + dashboard → docs güncelleme.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Tam profile startup baseline ==="
echo ""
echo "Önkoşul: Uygulama kapalı (Cmd+Q)."
echo "Süreç: profile açılır → SİZ giriş yapıp dashboard'a gelirsiniz → terminalde q."
echo ""

if [[ -x "$ROOT/scripts/ensure_macos_profile_signing.sh" ]]; then
  "$ROOT/scripts/ensure_macos_profile_signing.sh" || true
fi

exec "$ROOT/scripts/capture_startup_baseline.sh" "$@"
