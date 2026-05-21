#!/usr/bin/env bash
# Soğuk açılış baseline — profile modda [Perf] satırlarını dosyaya yazar ve özetler.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/docs/perf_logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
LOG_FILE="$LOG_DIR/startup_${STAMP}_profile.log"
PARSE="$ROOT/scripts/parse_perf_log.sh"

echo "=== Soğuk açılış baseline ==="
echo ""
echo "1. Uygulamayı tamamen kapatın (Cmd+Q)."
echo "2. Bu script profile modda açar; çıktı kaydedilir:"
echo "   $LOG_FILE"
echo "3. Kapatınca (q) otomatik özet yazdırılır."
echo "4. Özeti docs/perf_baseline.md şablonuna yapıştırın."
echo ""
echo "Beklenen startup_milestone sırası:"
echo "  main_entered → bootstrap_parallel_done → run_app → first_frame"
echo "  → role_shell_interactive → role_shell_resolved"
echo "  → screen_content_ready screen=consultant_dashboard|admin_dashboard ..."
echo ""
echo "Firebase Analytics (profile/release): olay startup_milestone"
echo "DevTools: Performance → Record (ilk 10 sn, sekme turu opsiyonel)."
echo ""
echo "İlk macOS profile build imza hatası: ./scripts/ensure_macos_profile_signing.sh"
echo "Tam ölçüm (giriş + dashboard): ./scripts/capture_startup_baseline_full.sh"
echo ""

_run() {
  if [[ -x scripts/run_with_shield.sh ]]; then
    scripts/run_with_shield.sh -d macos --profile "$@"
  else
    flutter run -d macos --profile "$@"
  fi
}

set +e
_run 2>&1 | tee "$LOG_FILE"
EXIT="${PIPESTATUS[0]:-0}"
set -e

if [[ -x "$PARSE" ]]; then
  "$PARSE" "$LOG_FILE"
elif [[ -f "$PARSE" ]]; then
  bash "$PARSE" "$LOG_FILE"
fi

if [[ -f "$ROOT/scripts/update_perf_baseline_from_log.py" ]]; then
  python3 "$ROOT/scripts/update_perf_baseline_from_log.py" "$LOG_FILE" --mode profile
fi

if [[ -f "$ROOT/scripts/check_perf_thresholds.py" ]]; then
  python3 "$ROOT/scripts/check_perf_thresholds.py" "$LOG_FILE" --mode profile || THRESH_EXIT=$?
  if [[ "${THRESH_EXIT:-0}" -ne 0 ]]; then
    echo "(Eşik uyarısı: giriş/dashboard eksik olabilir — role_shell ve screen satırlarını kontrol edin.)" >&2
  fi
fi

exit "$EXIT"
