"""Firebase Admin kimliği — repoya JSON koymadan yerel çalıştırma.

Öncelik:
1. `FIREBASE_SERVICE_ACCOUNT_JSON` (tam JSON metni)
2. `FIREBASE_SERVICE_ACCOUNT_FILE` (dosya yolu)
3. Bu klasörde `.service_account.json` (gitignore — dosyayı buraya kopyalayın)
"""

from __future__ import annotations

import os


def load_service_account_json() -> str:
    raw = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if raw:
        return raw
    path = os.environ.get("FIREBASE_SERVICE_ACCOUNT_FILE", "").strip()
    if path and os.path.isfile(path):
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    here = os.path.dirname(os.path.abspath(__file__))
    local = os.path.join(here, ".service_account.json")
    if os.path.isfile(local):
        with open(local, encoding="utf-8") as f:
            return f.read().strip()
    return ""
