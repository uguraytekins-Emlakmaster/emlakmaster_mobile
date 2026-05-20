#!/usr/bin/env bash
# [Perf] satırlarından özet tablo (capture_startup_baseline.sh çıktısı).
set -euo pipefail

LOG="${1:-}"
if [[ -z "$LOG" || ! -f "$LOG" ]]; then
  echo "Kullanım: $0 docs/perf_logs/startup_YYYY-MM-DD_HHMMSS_profile.log" >&2
  exit 1
fi

echo ""
echo "=== Perf özeti: $(basename "$LOG") ==="
echo ""

python3 - "$LOG" <<'PY'
import re
import sys
from pathlib import Path

log = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
milestones = []
screens = []
for line in log.splitlines():
    m = re.search(
        r"\[Perf\] startup_milestone name=(\S+) elapsed_ms=(\d+)",
        line,
    )
    if m:
        milestones.append((m.group(1), int(m.group(2))))
        continue
    s = re.search(
        r"\[Perf\] screen_content_ready screen=(\S+) (\d+)ms",
        line,
    )
    if s:
        screens.append((s.group(1), int(s.group(2))))

if milestones:
    print("Startup milestone (main() →):")
    print("| name | elapsed_ms |")
    print("|------|------------|")
    for name, ms in milestones:
        print(f"| {name} | {ms} |")
    print()
else:
    print("(startup_milestone satırı yok — uygulama profile modda açıldı mı?)")
    print()

if screens:
    print("screen_content_ready:")
    print("| screen | ms |")
    print("|--------|-----|")
    for name, ms in screens:
        print(f"| {name} | {ms} |")
    print()
else:
    print("(screen_content_ready yok — giriş + dashboard’a kadar bekleyin)")
    print()

print("Ham [Perf] satırları:")
for line in log.splitlines():
    if "[Perf]" in line:
        print(line)
PY

echo ""
echo "Kayıt: docs/perf_baseline.md şablonuna yukarıdaki tabloları yapıştırın."
