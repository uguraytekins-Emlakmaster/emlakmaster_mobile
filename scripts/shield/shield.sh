#!/usr/bin/env bash
#
# Koruma kalkanı — Proje genelinde kendini onaran kontroller.
# Tüm olumsuz senaryolara karşı fixer'ları sırayla çalıştırır.
# Kullanım: scripts/shield/shield.sh [--quiet] [fixer_adı]
# Örnek:   scripts/shield/shield.sh
#          scripts/shield/shield.sh 02_ios_plugin_order
#
set -e

SHIELD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# config.sh PROJECT_ROOT'u export eder
source "$SHIELD_DIR/config.sh"
cd "$PROJECT_ROOT"

QUIET=0
[[ "${1:-}" = "--quiet" ]] && QUIET=1 && shift
RUN_ONE="${1:-}"

# QUIET=1 iken [[ ]] false döner; set -e ile tüm shield çıkmaması için her zaman başarı.
log() { [[ $QUIET -eq 0 ]] && echo "$@" || true; }
run_fixer() {
  local f="$1"
  [[ ! -x "$f" ]] && chmod +x "$f" 2>/dev/null
  if [[ -n "$RUN_ONE" ]]; then
    [[ "$(basename "$f")" = "$RUN_ONE" ]] || return 0
  fi
  log "shield: çalışıyor — $(basename "$f")"
  "$f" || true
}

# Fixer'ları sırayla çalıştır (00_, 01_, ...)
FIXERS_DIR="$SHIELD_DIR/fixers"
if [[ ! -d "$FIXERS_DIR" ]]; then
  echo "shield: fixers dizini yok: $FIXERS_DIR" >&2
  exit 1
fi

[[ $QUIET -eq 0 ]] && echo "shield: PROJECT_ROOT=$PROJECT_ROOT" || true

for f in "$FIXERS_DIR"/[0-9][0-9]_*.sh; do
  [[ -f "$f" ]] && run_fixer "$f"
done

[[ $QUIET -eq 0 ]] && echo "shield: bitti." || true
