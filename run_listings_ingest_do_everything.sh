#!/usr/bin/env bash
# Kısayol: emlakmaster_mobile klasöründeyken çalıştırın.
exec "$(cd "$(dirname "$0")" && pwd)/scripts/listings_ingest_do_everything.sh" "$@"
