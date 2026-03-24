const { getAxios } = require("../httpClient");
const cheerio = require("cheerio");

/**
 * sahibinden.com konut listesi.
 * Öncelik: en yüksek. Site yapısı değişebilir; gerekirse güncellenir.
 * İl kodu ile URL: örn. Diyarbakır 21 -> arama sayfası
 */
async function fetchSahibinden(cityCode, cityName, districtName) {
  const out = [];
  try {
    // Sahibinden emlak-konut liste URL (il bazlı: a24=il no)
    const url = `https://www.sahibinden.com/emlak-konut?a24=${cityCode}&p=1`;
    const { data: html } = await getAxios().get(url, {
      timeout: 15000,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; EmlakMaster/1.0; +https://emlakmaster.app)",
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
      },
      maxRedirects: 3,
      validateStatus: (s) => s < 400,
    });
    const $ = cheerio.load(html);
    // Liste satırları: searchResultsItem veya tbody tr (site yapısına göre)
    $(".searchResultsItem, .searchResultsItemClassified, [data-id]").each((i, el) => {
      const $el = $(el);
      const linkEl = $el.find("a[href*='/ilan/']").first();
      const href = linkEl.attr("href");
      if (!href) return;
      const fullLink = href.startsWith("http") ? href : `https://www.sahibinden.com${href}`;
      const title = linkEl.text().trim() || $el.find(".classifiedTitle").text().trim() || "İlan";
      const priceText = $el.find(".classifiedsPrice, .searchResultsPriceValue").first().text().trim();
      const idMatch = fullLink.match(/\/ilan\/([^/?]+)/);
      const externalId = idMatch ? idMatch[1] : `sb-${Date.now()}-${i}`;
      const img = $el.find("img[data-src], img[src]").first().attr("data-src") || $el.find("img").first().attr("src");
      let district = null;
      $el.find(".searchResultsLocationValue, .classifiedLocation").each((_, loc) => {
        const t = $(loc).text().trim();
        if (t && t.length < 30) district = t;
      });
      if (districtName && district && !district.includes(districtName)) return; // ilçe filtresi
      out.push({
        externalId,
        title: title.slice(0, 200),
        priceText: priceText || null,
        priceValue: parsePrice(priceText),
        district: district || districtName,
        link: fullLink,
        imageUrl: img && img.startsWith("http") ? img : null,
        postedAt: new Date(),
        roomCount: null,
        sqm: null,
      });
    });
    // Eğer yeni yapıda liste farklı selector ile geliyorsa alternatif
    if (out.length === 0) {
      $("tr[data-id]").each((i, el) => {
        const $el = $(el);
        const dataId = $el.attr("data-id");
        const linkEl = $el.find("a[href*='/ilan/']").first();
        const href = linkEl.attr("href");
        if (!href || !dataId) return;
        const fullLink = href.startsWith("http") ? href : `https://www.sahibinden.com${href}`;
        const title = linkEl.text().trim() || "İlan";
        const priceText = $el.find(".searchResultsPriceValue").text().trim();
        out.push({
          externalId: dataId,
          title: title.slice(0, 200),
          priceText: priceText || null,
          priceValue: parsePrice(priceText),
          district: districtName,
          link: fullLink,
          imageUrl: null,
          postedAt: new Date(),
          roomCount: null,
          sqm: null,
        });
      });
    }
  } catch (e) {
    console.warn("sahibinden fetch error", e.message);
  }
  return out.slice(0, 30);
}

function parsePrice(text) {
  if (!text) return null;
  const numStr = text.replace(/[^\d,.]/g, "").replace(",", ".");
  const n = parseFloat(numStr);
  return isNaN(n) ? null : n;
}

module.exports = { fetchSahibinden };
