#!/usr/bin/env bash
# Xcode derlemesindeki uyarıları sayar ve dosya bazında özetler (Pods dahil).
# Kullanım: proje kökünden: bash scripts/analyze_ios_build_warnings.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/ios"

DEST="${1:-generic/platform=iOS Simulator}"
echo "==> xcodebuild (destination: $DEST) — bu birkaç dakika sürebilir."
echo ""

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

set +e
xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "$DEST" \
  build \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$LOG"
XC="${PIPESTATUS[0]}"
set -e

echo ""
echo "========== Özet =========="
WARN_TOTAL=$(grep "warning:" "$LOG" 2>/dev/null | wc -l | tr -d ' ')
ERR_TOTAL=$(grep "error:" "$LOG" 2>/dev/null | wc -l | tr -d ' ')
echo "Uyarı satırı (warning:): ${WARN_TOTAL:-0}"
echo "Hata satırı (error:): ${ERR_TOTAL:-0}"

echo ""
echo "==> İlk 40 uyarı satırı (ham):"
grep "warning:" "$LOG" 2>/dev/null | head -40 || true

echo ""
echo "==> 'Pods/' içeren uyarı sayısı:"
grep "warning:" "$LOG" 2>/dev/null | grep -c "Pods/" || echo "0"

echo ""
echo "==> 'Runner/' içeren uyarı sayısı:"
grep "warning:" "$LOG" 2>/dev/null | grep -c "Runner/" || echo "0"

echo ""
echo "xcodebuild çıkış kodu: $XC"
exit "$XC"
