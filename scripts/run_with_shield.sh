#!/usr/bin/env bash
# flutter run öncesi shield çalıştırır; sonra flutter run [argumanlar].
# Kullanım: scripts/run_with_shield.sh [flutter run argümanları]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
"$SCRIPT_DIR/shield/shield.sh" --quiet
exec flutter run "$@"
