#!/usr/bin/env bash
# Kritik dosyaların varlığını kontrol et; eksikse uyar (oluşturmaz).
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
CRITICAL=(
  pubspec.yaml
  lib/main.dart
)
MISSING=()
for f in "${CRITICAL[@]}"; do
  [[ ! -e "$f" ]] && MISSING+=("$f")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "shield: 06_critical_files — Eksik kritik dosya: ${MISSING[*]}" >&2
fi
exit 0
