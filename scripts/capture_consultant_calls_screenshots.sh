#!/usr/bin/env bash
# Captures Çağrılarım UI proof frames via widget tests (headless-safe).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build/screenshots/screen2_calls
flutter test test/features/calls/consultant_calls_visual_proof_test.dart "$@"
