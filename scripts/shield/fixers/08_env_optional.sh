#!/usr/bin/env bash
# Opsiyonel: .env.example var ama .env yoksa bilgi ver (kopyalamıyoruz, gizli bilgi riski).
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
[[ ! -f .env.example ]] && exit 0
[[ -f .env ]] && exit 0
echo "shield: 08_env_optional — .env yok (.env.example mevcut). Gerekirse kopyalayın: cp .env.example .env"
exit 0
