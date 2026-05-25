#!/usr/bin/env bash
# Captures Müşterilerim UI proof frames via widget tests (headless-safe).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build/screenshots/screen3_customers
flutter test test/features/crm_customers/consultant_customers_visual_proof_test.dart "$@"
