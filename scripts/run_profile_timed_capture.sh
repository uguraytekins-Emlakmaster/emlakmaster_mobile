#!/usr/bin/env bash
# Profile modda süre sınırlı çalıştırma (macOS'ta timeout yok).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DURATION="${CAPTURE_DURATION_SEC:-120}"
LOG_DIR="$ROOT/docs/perf_logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
LOG_FILE="$LOG_DIR/startup_${STAMP}_profile.log"

echo "Log: $LOG_FILE (${DURATION}s)"

flutter run -d macos --profile "$@" > >(tee "$LOG_FILE") 2>&1 &
RUN_PID=$!

cleanup() {
  kill -INT "$RUN_PID" 2>/dev/null || true
  wait "$RUN_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

sleep "$DURATION"
cleanup
trap - EXIT INT TERM

if [[ -x "$ROOT/scripts/parse_perf_log.sh" ]]; then
  "$ROOT/scripts/parse_perf_log.sh" "$LOG_FILE"
fi

if [[ -f "$ROOT/scripts/check_perf_thresholds.py" ]]; then
  python3 "$ROOT/scripts/check_perf_thresholds.py" "$LOG_FILE" --mode profile || true
fi

if [[ "${SKIP_BASELINE_UPDATE:-}" != "1" ]] && [[ -f "$ROOT/scripts/update_perf_baseline_from_log.py" ]]; then
  python3 "$ROOT/scripts/update_perf_baseline_from_log.py" "$LOG_FILE" --mode profile \
    --note "run_profile_timed_capture ${DURATION}s"
fi

echo "LOG_FILE=$LOG_FILE"
