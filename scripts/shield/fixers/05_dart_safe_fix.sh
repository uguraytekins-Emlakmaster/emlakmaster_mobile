#!/usr/bin/env bash
# Dart: Otomatik düzeltilebilecek analiz hataları (dart fix --apply).
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
# Sadece güvenli düzeltmeler; başarısız olursa sessizce devam et
dart fix --apply lib/ 2>/dev/null || true
exit 0
