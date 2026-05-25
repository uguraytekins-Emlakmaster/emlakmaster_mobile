#!/usr/bin/env bash
# Captures Görevlerim UI proof frames via widget tests (headless-safe).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build/screenshots/screen4_tasks
flutter test test/features/tasks/consultant_tasks_visual_proof_test.dart "$@"
flutter test test/features/tasks/consultant_tasks_live_macos_proof_test.dart "$@"
