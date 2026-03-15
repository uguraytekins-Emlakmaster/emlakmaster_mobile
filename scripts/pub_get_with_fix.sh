#!/usr/bin/env bash
# flutter pub get çalıştırır, ardından tüm koruma kalkanını (shield) çalıştırır.
# Kullanım: scripts/pub_get_with_fix.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
flutter pub get
"$SCRIPT_DIR/shield/shield.sh" --quiet
