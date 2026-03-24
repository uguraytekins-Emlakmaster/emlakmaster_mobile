#!/usr/bin/env bash
# GitHub repo Variables (MAX_LISTINGS, CITY_NAME, DISTRICT_NAME) — isteğe bağlı.
# Önkoşul: gh auth login

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v gh &>/dev/null; then
  echo "gh yok: brew install gh && gh auth login"
  exit 1
fi

MAX="${MAX_LISTINGS:-30}"
CITY="${CITY_NAME:-Diyarbakır}"
DIST="${DISTRICT_NAME:-}"

echo "gh variable set MAX_LISTINGS=$MAX"
gh variable set MAX_LISTINGS --body "$MAX"

echo "gh variable set CITY_NAME=$CITY"
gh variable set CITY_NAME --body "$CITY"

if [[ -n "$DIST" ]]; then
  echo "gh variable set DISTRICT_NAME=$DIST"
  gh variable set DISTRICT_NAME --body "$DIST"
else
  echo "DISTRICT_NAME boş — atlandı (varsayılan)."
fi

echo "Tamam."
