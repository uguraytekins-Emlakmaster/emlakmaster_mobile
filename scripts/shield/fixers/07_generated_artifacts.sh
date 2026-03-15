#!/usr/bin/env bash
# Üretilmiş dosyalar: .flutter-plugins, .flutter-plugins-dependencies; yoksa pub get.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
NEED_PUB=0
[[ ! -f .flutter-plugins ]] && NEED_PUB=1
[[ ! -f .dart_tool/package_config.json ]] && NEED_PUB=1
if [[ $NEED_PUB -eq 1 ]]; then
  echo "shield: 07_generated_artifacts — Flutter üretilmiş dosyalar eksik, pub get çalıştırılıyor."
  flutter pub get 2>/dev/null || true
fi
exit 0
