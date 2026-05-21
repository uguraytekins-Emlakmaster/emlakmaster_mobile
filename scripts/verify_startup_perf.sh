#!/usr/bin/env bash
# CI / PR: otomatik startup milestone regresyonu (test binding, imza gerekmez).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/docs/perf_logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
LOG_FILE="$LOG_DIR/startup_${STAMP}_ci_verify.log"

echo "=== Startup perf regresyon (automated) ==="
echo "Log: $LOG_FILE"

flutter test test/performance/startup_baseline_capture_test.dart \
  --dart-define=CAPTURE_STARTUP_PERF=true \
  2>&1 | tee "$LOG_FILE"

python3 "$ROOT/scripts/check_perf_thresholds.py" "$LOG_FILE" --mode automated

echo "Regresyon kontrolü geçti."
