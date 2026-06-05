#!/usr/bin/env bash
# Profile modda shell performans turu — DevTools Performance kaydı için.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Axion CRM — profile performans ==="
echo "1. Uygulama profile modda açılacak (macOS)."
echo "2. DevTools → Performance → Record"
echo "3. Sekmeler: Özet → Çağrılar → Müşteriler → Görevler → İlanlar"
echo "4. Debug konsolda [Perf] screen_content_ready satırlarına bak"
echo "5. Soğuk açılış kaydı: ./scripts/capture_startup_baseline.sh"
echo "6. Detay: docs/PERFORMANCE_PROFILING.md"
echo ""

if [[ -x scripts/run_with_shield.sh ]]; then
  exec scripts/run_with_shield.sh -d macos --profile "$@"
else
  exec flutter run -d macos --profile "$@"
fi
