#!/usr/bin/env python3
"""
Sahibinden liste sayfasını Playwright ile açar, HTML’den ilanları çıkarır ve
Firestore external_listings’e yazar.

- Cloudflare tespiti: log + GitHub ::warning::
- trendPct: aynı ilan için önceki ingest’teki priceValue ile karşılaştırma (varsa).

Kullanım (yerel):
  # JSON veya: indirdiğin dosyayı .service_account.json olarak bu klasöre koy
  export CITY_CODE=21
  export CITY_NAME=Diyarbakır
  export MAX_LISTINGS=30
  pip install -r requirements.txt && playwright install chromium
  python ingest_sahibinden.py
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from typing import Any

from firebase_admin import credentials, firestore, initialize_app
from firebase_credentials import load_service_account_json
from ingest_parse import (
    compute_trend_pct,
    is_cloudflare_challenge,
    parse_sahibinden_html,
    slug_doc_id,
)
from playwright.sync_api import sync_playwright


def main() -> int:
    raw_json = load_service_account_json()
    if not raw_json:
        print(
            "Firebase kimliği yok: FIREBASE_SERVICE_ACCOUNT_JSON, "
            "FIREBASE_SERVICE_ACCOUNT_FILE veya tools/github_listings_ingest/.service_account.json",
            file=sys.stderr,
        )
        return 1

    city_code = os.environ.get("CITY_CODE", "21").strip() or "21"
    city_name = os.environ.get("CITY_NAME", "Diyarbakır").strip() or "Diyarbakır"
    district = os.environ.get("DISTRICT_NAME", "").strip() or None
    try:
        max_listings = max(1, min(100, int(os.environ.get("MAX_LISTINGS", "30"))))
    except ValueError:
        max_listings = 30

    url = f"https://www.sahibinden.com/emlak-konut?a24={city_code}&p=1"
    print(f"Fetching {url} … (max_listings={max_listings})")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(
            user_agent=(
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
        )
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=90000)
            page.wait_for_timeout(5000)
            html = page.content()
        finally:
            browser.close()

    cf = is_cloudflare_challenge(html)
    if cf:
        msg = (
            "Cloudflare / bot sayfası veya çok kısa HTML tespit edildi. "
            "İlan çıkmıyorsa log’u kontrol edin."
        )
        print(f"::warning::{msg}")
        print(f"UYARI: {msg}", file=sys.stderr)

    items = parse_sahibinden_html(html, district, max_listings)
    print(f"Parsed {len(items)} satır.")

    cred = credentials.Certificate(json.loads(raw_json))
    initialize_app(cred)
    db = firestore.client()
    col = db.collection("external_listings")
    now = datetime.now(timezone.utc)

    if not items:
        print(
            "İlan bulunamadı (Cloudflare, seçici değişimi veya boş liste). "
            "Çıkış kodu 0 — zamanlayıcıyı kırmamak için."
        )
        return 0

    batch = db.batch()
    n = 0
    for item in items:
        doc_id = slug_doc_id("sahibinden", item["externalId"])
        ref = col.document(doc_id)
        snap = ref.get()
        old_pv = None
        if snap.exists:
            prev = snap.to_dict() or {}
            v = prev.get("priceValue")
            if isinstance(v, (int, float)):
                old_pv = float(v)

        new_pv = item.get("priceValue")
        if isinstance(new_pv, (int, float)):
            new_pv = float(new_pv)
        else:
            new_pv = None

        trend_pct = compute_trend_pct(old_pv, new_pv)

        data: dict[str, Any] = {
            "source": "sahibinden",
            "externalId": item["externalId"],
            "title": item["title"],
            "propertyType": None,
            "priceText": item.get("priceText"),
            "priceValue": new_pv,
            "cityCode": city_code,
            "cityName": city_name,
            "districtName": item.get("district"),
            "link": item["link"],
            "imageUrl": item.get("imageUrl"),
            "postedAt": now,
            "roomCount": None,
            "sqm": None,
            "ingestedBy": "github_actions",
            "ingestedAt": now,
        }
        if trend_pct is not None:
            data["trendPct"] = trend_pct
            data["trendBasis"] = "prev_ingest_price"

        batch.set(ref, data, merge=True)
        n += 1
        if n % 400 == 0:
            batch.commit()
            batch = db.batch()

    if n % 400 != 0:
        batch.commit()

    print(f"Firestore yazıldı: {n} doküman (trendPct: önceki priceValue ile).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
