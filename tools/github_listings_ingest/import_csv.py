#!/usr/bin/env python3
"""
Plan B: CSV dosyasından external_listings’e toplu yazım (Admin SDK).
Ücretli proxy / otomatik çekim çalışmazken manuel veya Excel export ile doldurmak için.

Örnek CSV başlıkları (UTF-8):
  source,externalId,title,propertyType,priceText,priceValue,cityCode,cityName,districtName,link,imageUrl

source: sahibinden | emlakjet | hepsiEmlak | demo

  python import_csv.py yol/ilanlar.csv
  # Kimlik: .service_account.json veya FIREBASE_SERVICE_ACCOUNT_FILE
"""

from __future__ import annotations

import csv
import json
import re
import sys
from datetime import datetime, timezone

from firebase_admin import credentials, firestore, initialize_app

from firebase_credentials import load_service_account_json


def _slug_doc_id(source: str, external_id: str) -> str:
    raw = f"{source}_{external_id}"
    return re.sub(r"[/.#\s]", "_", raw)[:300]


def main() -> int:
    if len(sys.argv) < 2:
        print("Kullanım: python import_csv.py <dosya.csv>", file=sys.stderr)
        return 1

    path = sys.argv[1]
    raw_json = load_service_account_json()
    if not raw_json:
        print(
            "Firebase kimliği yok (JSON, FIREBASE_SERVICE_ACCOUNT_FILE veya .service_account.json).",
            file=sys.stderr,
        )
        return 1

    cred = credentials.Certificate(json.loads(raw_json))
    initialize_app(cred)
    db = firestore.client()
    col = db.collection("external_listings")
    now = datetime.now(timezone.utc)

    allowed = frozenset({"sahibinden", "emlakjet", "hepsiEmlak", "demo"})
    n = 0
    batch = db.batch()
    with open(path, encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            src = (row.get("source") or "").strip()
            ext = (row.get("externalId") or "").strip()
            if src not in allowed or not ext:
                print(f"Satır atlandı (source/externalId): {row}", file=sys.stderr)
                continue
            doc_id = _slug_doc_id(src, ext)
            ref = col.document(doc_id)
            pv = row.get("priceValue")
            price_val = None
            if pv is not None and str(pv).strip() != "":
                try:
                    price_val = float(str(pv).replace(",", "."))
                except ValueError:
                    price_val = None
            data = {
                "source": src,
                "externalId": ext,
                "title": (row.get("title") or "İlan")[:500],
                "propertyType": (row.get("propertyType") or "").strip() or None,
                "priceText": (row.get("priceText") or "").strip() or None,
                "priceValue": price_val,
                "cityCode": (row.get("cityCode") or "21").strip(),
                "cityName": (row.get("cityName") or "").strip() or "—",
                "districtName": (row.get("districtName") or "").strip() or None,
                "link": (row.get("link") or "").strip() or "https://example.com",
                "imageUrl": (row.get("imageUrl") or "").strip() or None,
                "postedAt": now,
                "roomCount": None,
                "sqm": None,
                "ingestedBy": "csv_import",
                "ingestedAt": now,
            }
            batch.set(ref, data, merge=True)
            n += 1
            if n % 400 == 0:
                batch.commit()
                batch = db.batch()

    if n % 400 != 0:
        batch.commit()

    print(f"Tamam: {n} satır Firestore’a yazıldı.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
