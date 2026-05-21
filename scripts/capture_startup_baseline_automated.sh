#!/usr/bin/env bash
# Agent/CI: macOS imzası olmadan startup milestone baseline (CAPTURE_STARTUP_PERF test).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/docs/perf_logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
LOG_FILE="$LOG_DIR/startup_${STAMP}_automated.log"

echo "=== Otomatik startup baseline (test binding) ==="
echo "Log: $LOG_FILE"

flutter test test/performance/startup_baseline_capture_test.dart \
  --dart-define=CAPTURE_STARTUP_PERF=true \
  2>&1 | tee "$LOG_FILE"

"$ROOT/scripts/parse_perf_log.sh" "$LOG_FILE"

if [[ -x "$ROOT/scripts/update_perf_baseline_from_log.py" ]]; then
  python3 "$ROOT/scripts/update_perf_baseline_from_log.py" "$LOG_FILE" \
    --device "macOS (automated test)" \
    --note "CAPTURE_STARTUP_PERF; profile macOS için capture_startup_baseline.sh"
fi

echo "Bitti: $LOG_FILE"
