#!/usr/bin/env bash
# Web build'i yerelde sunar (tarayıcıdan açılır).
# Önce build: flutter build web
# Kullanım: scripts/serve_web.sh [port]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
PORT="${1:-8080}"
if [[ ! -d build/web ]]; then
  echo "Önce web build alın: flutter build web"
  flutter build web
fi
echo "Web uygulaması http://localhost:$PORT adresinde açılıyor."
exec flutter run -d web-server --web-port="$PORT" --web-hostname=0.0.0.0
