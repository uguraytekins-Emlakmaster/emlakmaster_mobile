#!/usr/bin/env bash
# macOS profile build imza/provisioning yoksa bir kez oluşturur.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

_probe() {
  flutter build macos --profile 2>&1 | tee /tmp/emlakmaster_profile_build_probe.log
}

echo "=== macOS profile imza kontrolü ==="
if _probe | tail -3 | grep -q "Built build/macos"; then
  echo "Profile build zaten çalışıyor."
  exit 0
fi

if ! grep -q "No profiles for" /tmp/emlakmaster_profile_build_probe.log 2>/dev/null; then
  echo "Profile build başarısız (imza dışı neden). Log: /tmp/emlakmaster_profile_build_probe.log" >&2
  exit 1
fi

echo "Provisioning profile oluşturuluyor (-allowProvisioningUpdates)…"
cd "$ROOT/macos"
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Profile \
  -allowProvisioningUpdates build

cd "$ROOT"
if _probe | tail -3 | grep -q "Built build/macos"; then
  echo "Profile build hazır."
  exit 0
fi

echo "Profile build hâlâ başarısız. Xcode → Signing & Capabilities → Team seçin." >&2
exit 1
