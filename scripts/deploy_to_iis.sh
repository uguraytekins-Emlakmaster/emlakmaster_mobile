#!/usr/bin/env bash
# EmlakMaster Web — IIS (veya herhangi bir web kökü) için tek komutla dağıtım.
# build/web içeriğini DEST dizinine kopyalar. Önce: flutter build web --base-href "/"
# Kullanım:
#   scripts/deploy_to_iis.sh /path/to/wwwroot
#   DEST=/Volumes/IIS/wwwroot scripts/deploy_to_iis.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$PROJECT_ROOT/build/web"
[[ -d "$PROJECT_ROOT/release_iis" ]] && SOURCE="$PROJECT_ROOT/release_iis"
DEST="${1:-$DEST}"

if [[ -z "$DEST" ]]; then
  echo "Hedef dizin gerekli. Ornek: $0 /path/to/wwwroot"
  echo "  veya: DEST=/path/to/wwwroot $0"
  exit 1
fi

if [[ ! -d "$SOURCE" ]]; then
  echo "Build bulunamadi. Calistiriliyor: flutter build web --base-href \"/\""
  (cd "$PROJECT_ROOT" && flutter build web --base-href "/")
fi

mkdir -p "$DEST"
echo "Kopyalaniyor: $SOURCE -> $DEST"
rsync -a --delete "$SOURCE/" "$DEST/" 2>/dev/null || {
  (cd "$SOURCE" && tar cf - .) | (cd "$DEST" && tar xf -)
}
echo "IIS hedefi guncellendi: $DEST"
