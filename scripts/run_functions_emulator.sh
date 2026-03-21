#!/usr/bin/env bash
# Yerel Firebase Functions emülatörü (Blaze gerekmez).
# Uygulama: flutter run --dart-define=USE_FUNCTIONS_EMULATOR=true
# iOS Sim / macOS: 127.0.0.1:5001 | Android emülatör: otomatik 10.0.2.2 eşlemesi (cloud_functions)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/functions"
npm install
cd "$ROOT"
exec firebase emulators:start --only functions --project emlak-master
