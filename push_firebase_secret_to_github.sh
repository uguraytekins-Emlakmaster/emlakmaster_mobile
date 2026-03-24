#!/usr/bin/env bash
# Kısayol: emlakmaster_mobile klasöründeyken çalıştırın.
# Kullanım:
#   bash push_firebase_secret_to_github.sh ~/Downloads/firebase-adminsdk-xxxxx.json
exec "$(cd "$(dirname "$0")" && pwd)/scripts/github_listings_push_secret.sh" "$@"
