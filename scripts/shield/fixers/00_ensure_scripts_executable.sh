#!/usr/bin/env bash
# Tüm .sh script'lerini çalıştırılabilir yapar (izin kaybı / taşıma sonrası).
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
FIXED=0
for pattern in scripts/*.sh scripts/shield/*.sh scripts/shield/fixers/*.sh scripts/shield/hooks/*.sample; do
  for f in $pattern; do
    [[ -f "$f" ]] && [[ ! -x "$f" ]] && chmod +x "$f" && FIXED=$((FIXED+1)) && echo "  +x $f"
  done
done 2>/dev/null || true
[[ $FIXED -gt 0 ]] && echo "shield: 00_ensure_scripts_executable — $FIXED dosya çalıştırılabilir yapıldı."
exit 0
