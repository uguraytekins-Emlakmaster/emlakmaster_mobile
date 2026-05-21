#!/usr/bin/env bash
# Developer ID sertifikası kurulumu için kısayol.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Developer ID kurulumu ==="
echo ""
echo "1. Apple Developer → Certificates → + → Developer ID Application"
echo "2. İndirilen .cer dosyasına çift tık (Keychain'e eklenir)"
echo "3. Xcode → Runner target → Signing & Capabilities → Release → Team + Automatic"
echo "4. flutter build macos --release"
echo "5. NOTARIZE=1 ./scripts/package_macos_release.sh"
echo ""
echo "Yüklü kimlikler:"
security find-identity -v -p codesigning 2>/dev/null | grep -E "Developer ID|Apple Development" || true
echo ""

open "https://developer.apple.com/account/resources/certificates/list" 2>/dev/null || true
open "$ROOT/macos/Runner.xcodeproj" 2>/dev/null || true
