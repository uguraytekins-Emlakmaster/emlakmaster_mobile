# Shield ortak ayarlar. Kaynak: shield.sh veya fixer'lar.
# PROJECT_ROOT: Flutter proje kökü (pubspec.yaml'ın olduğu dizin).
# SHIELD_DIR: scripts/shield dizini.

SHIELD_SOURCE="${BASH_SOURCE[0]:-$0}"
[[ -z "${SHIELD_DIR}" ]] && SHIELD_DIR="$(cd "$(dirname "$SHIELD_SOURCE")" && pwd)"

# Flutter proje kökü: pubspec.yaml aranıyor (shield dizininden yukarı)
_find_root() {
  local d="$SHIELD_DIR"
  while [[ "$d" != "/" ]]; do
    [[ -f "$d/pubspec.yaml" ]] && echo "$d" && return 0
    d="$(dirname "$d")"
  done
  return 1
}
PROJECT_ROOT="$(_find_root)"
if [[ -z "$PROJECT_ROOT" ]] || [[ ! -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
  echo "shield: pubspec.yaml bulunamadı." >&2
  exit 1
fi

FIXERS_DIR="$SHIELD_DIR/fixers"
export PROJECT_ROOT SHIELD_DIR FIXERS_DIR
