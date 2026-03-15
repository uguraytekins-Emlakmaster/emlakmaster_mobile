#!/usr/bin/env bash
# Eski build çıktıları: build/ ve .dart_tool/build bazen bozulur; analiz hata verirse temizlenebilir.
# Bu fixer sadece .dart_tool/build'i kaldırır (hafif); tam clean shield içinde 01'de yapılıyor.
set -e
# shellcheck source=../config.sh
source "$(dirname "$0")/../config.sh"
cd "$PROJECT_ROOT"
# build/ klasörü çok büyükse ve disk dolu uyarısı varsa kullanıcı flutter clean yapabilir; otomatik silmeyelim.
exit 0
