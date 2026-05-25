#!/usr/bin/env bash
# macOS live window capture — Görevlerim tab (consultant shell).
# Usage: run while emlakmaster_mobile is open on Görevlerim (4th bottom nav item).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/screenshots/screen4_tasks/06_live_macos_consultant_tasks.png"
mkdir -p "$(dirname "$OUT")"

APP="emlakmaster_mobile"
if ! pgrep -xq "$APP"; then
  echo "error: $APP is not running. Launch with ./scripts/run_with_shield.sh -d macos first."
  exit 1
fi

osascript <<'APPLESCRIPT' || true
tell application "emlakmaster_mobile" to activate
delay 0.8
APPLESCRIPT

WIN_ID=$(osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "emlakmaster_mobile"
    if (count of windows) is 0 then return ""
    return id of front window
  end tell
end tell
APPLESCRIPT
)

if [[ -z "$WIN_ID" ]]; then
  echo "error: could not resolve emlakmaster_mobile window id"
  exit 1
fi

screencapture -x -l "$WIN_ID" "$OUT"
echo "saved: $OUT"
ls -la "$OUT"
