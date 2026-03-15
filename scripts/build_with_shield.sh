#!/usr/bin/env bash
# flutter build öncesi shield çalıştırır; sonra flutter build [argumanlar].
# Kullanım: scripts/build_with_shield.sh [flutter build argümanları]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
"$SCRIPT_DIR/shield/shield.sh" --quiet
exec flutter build "$@"
