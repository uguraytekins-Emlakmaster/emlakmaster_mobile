"""ingest_parse — birim testleri (ağ / Firebase yok)."""

from __future__ import annotations

from ingest_parse import (
    compute_trend_pct,
    is_cloudflare_challenge,
    parse_price,
    parse_sahibinden_html,
    slug_doc_id,
)


def test_parse_price_tr() -> None:
    assert parse_price("4250000 TL") == 4250000.0


def test_slug_doc_id() -> None:
    assert "sahibinden" in slug_doc_id("sahibinden", "abc-123")


def test_cloudflare_short_html() -> None:
    assert is_cloudflare_challenge("") is True
    assert is_cloudflare_challenge("x" * 100) is True


def test_cloudflare_challenge_page() -> None:
    html = "x" * 2500 + " Just a moment "
    assert is_cloudflare_challenge(html) is True


def test_cloudflare_clean_long_html() -> None:
    html = "<!DOCTYPE html><html><body>" + ("<p>ok</p>" * 400) + "</body></html>"
    assert len(html) > 2000
    assert is_cloudflare_challenge(html) is False


def test_parse_listing_row() -> None:
    html = """
    <html><body>
    <div class="searchResultsItem">
      <a href="/ilan/test-id-1-baslik">Satılık Daire Merkez</a>
      <span class="classifiedsPrice">4250000 TL</span>
      <span class="searchResultsLocationValue">Kayapınar</span>
    </div>
    </body></html>
    """
    html = html + ("<!--pad-->" * 500)
    items = parse_sahibinden_html(html, None, 10)
    assert len(items) >= 1
    assert items[0]["externalId"] == "test-id-1-baslik"
    assert "Daire" in items[0]["title"] or "Satılık" in items[0]["title"]
    assert items[0]["priceValue"] == 4250000.0


def test_parse_regex_fallback() -> None:
    html = "x" * 2100
    html += '<a href="https://www.sahibinden.com/ilan/xyz-999-detay">x</a>'
    items = parse_sahibinden_html(html, None, 5)
    assert any(i["externalId"] == "xyz-999-detay" for i in items)


def test_compute_trend_pct() -> None:
    assert compute_trend_pct(100.0, 102.0) == 2.0
    assert compute_trend_pct(100.0, 97.5) == -2.5
    assert compute_trend_pct(None, 100.0) is None
    assert compute_trend_pct(0.0, 100.0) is None
