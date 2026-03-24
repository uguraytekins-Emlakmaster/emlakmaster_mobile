"""
Saf parse + Cloudflare heuristics (Playwright / Firebase yok) — test ve yeniden kullanım.
"""

from __future__ import annotations

import re
from typing import Any

from bs4 import BeautifulSoup


def parse_price(text: str | None) -> float | None:
    if not text:
        return None
    num_str = re.sub(r"[^\d,.]", "", text).replace(",", ".")
    try:
        n = float(num_str)
        return n if not (n != n) else None
    except ValueError:
        return None


def slug_doc_id(source: str, external_id: str) -> str:
    raw = f"{source}_{external_id}"
    return re.sub(r"[/.#\s]", "_", raw)[:300]


def is_cloudflare_challenge(html: str) -> bool:
    """Ham HTML’de bot / doğrulama sayfası belirtileri (heuristic)."""
    if not html or len(html) < 2000:
        return True
    lower = html.lower()
    markers = (
        "just a moment",
        "cf-browser-verification",
        "checking your browser",
        "ddos protection by cloudflare",
        "enable javascript and cookies",
        "ray id",
        "attention required",
        "captcha",
    )
    return any(m in lower for m in markers)


def parse_sahibinden_html(
    html: str,
    district_filter: str | None,
    max_items: int,
) -> list[dict[str, Any]]:
    """functions/fetchers/sahibinden.js ile uyumlu (BeautifulSoup)."""
    soup = BeautifulSoup(html, "html.parser")
    out: list[dict[str, Any]] = []
    seen: set[str] = set()

    selectors = [".searchResultsItem", ".searchResultsItemClassified", "[data-id]"]
    for sel in selectors:
        for el in soup.select(sel):
            link_el = el.select_one("a[href*='/ilan/']")
            if not link_el:
                continue
            href = link_el.get("href") or ""
            if not href:
                continue
            full = href if href.startswith("http") else f"https://www.sahibinden.com{href}"
            id_m = re.search(r"/ilan/([^/?]+)", full)
            external_id = id_m.group(1) if id_m else f"sb-{len(out)}"
            if external_id in seen:
                continue
            title = (link_el.get_text() or "").strip() or "İlan"
            price_el = el.select_one(".classifiedsPrice, .searchResultsPriceValue")
            price_text = price_el.get_text().strip() if price_el else None
            district = None
            for loc in el.select(".searchResultsLocationValue, .classifiedLocation"):
                t = loc.get_text().strip()
                if t and len(t) < 40:
                    district = t
                    break
            if district_filter and district and district_filter not in district:
                continue
            img_el = el.select_one("img[data-src], img[src]")
            img = None
            if img_el:
                img = img_el.get("data-src") or img_el.get("src")
                if img and not img.startswith("http"):
                    img = None
            seen.add(external_id)
            pt = parse_price(price_text)
            out.append(
                {
                    "externalId": external_id,
                    "title": title[:200],
                    "priceText": price_text,
                    "priceValue": pt,
                    "district": district or district_filter,
                    "link": full,
                    "imageUrl": img,
                }
            )
            if len(out) >= max_items:
                return out[:max_items]
        if out:
            break

    if not out:
        for m in re.finditer(
            r"https?://www\.sahibinden\.com/ilan/[^\"\s<>\?]+", html, re.I
        ):
            full = m.group(0)
            id_m = re.search(r"/ilan/([^/?]+)", full)
            if not id_m:
                continue
            external_id = id_m.group(1)
            if external_id in seen:
                continue
            seen.add(external_id)
            out.append(
                {
                    "externalId": external_id,
                    "title": "İlan",
                    "priceText": None,
                    "priceValue": None,
                    "district": district_filter,
                    "link": full,
                    "imageUrl": None,
                }
            )
            if len(out) >= max_items:
                break

    return out[:max_items]


def compute_trend_pct(old_pv: float | None, new_pv: float | None) -> float | None:
    if old_pv is None or new_pv is None:
        return None
    if old_pv <= 0:
        return None
    return round((new_pv - old_pv) / old_pv * 100.0, 2)
