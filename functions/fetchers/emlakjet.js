const axios = require("axios");
const cheerio = require("cheerio");

/**
 * emlakjet.com – il/ilçe bazlı son ilanlar.
 * Site yapısına göre selector'lar güncellenebilir.
 */
async function fetchEmlakjet(cityCode, cityName, districtName) {
  const out = [];
  try {
    const citySlug = cityName.toLowerCase().replace(/ğ/g, "g").replace(/ü/g, "u").replace(/ş/g, "s").replace(/ı/g, "i").replace(/ö/g, "o").replace(/ç/g, "c").replace(/\s+/g, "-");
    const url = `https://www.emlakjet.com/satilik-konut/${citySlug}/`;
    const { data: html } = await axios.get(url, {
      timeout: 15000,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; EmlakMaster/1.0)",
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "tr-TR,tr;q=0.9",
      },
      validateStatus: (s) => s < 400,
    });
    const $ = cheerio.load(html);
    $("[data-listings] a[href*='/ilan/'], .listing-card a, .property-card a").each((i, el) => {
      const $el = $(el);
      const href = $el.attr("href");
      if (!href) return;
      const fullLink = href.startsWith("http") ? href : `https://www.emlakjet.com${href}`;
      const title = $el.find("h2, h3, .title, .listing-title").first().text().trim() || $el.text().trim().slice(0, 100);
      const priceText = $el.find(".price, .listing-price").first().text().trim();
      const externalId = fullLink.split("/").filter(Boolean).pop() || `ej-${Date.now()}-${i}`;
      out.push({
        externalId,
        title: title.slice(0, 200),
        priceText: priceText || null,
        priceValue: parsePrice(priceText),
        district: districtName,
        link: fullLink,
        imageUrl: $el.find("img").first().attr("src") || null,
        postedAt: new Date(),
        roomCount: null,
        sqm: null,
      });
    });
  } catch (e) {
    console.warn("emlakjet fetch error", e.message);
  }
  return out.slice(0, 20);
}

function parsePrice(text) {
  if (!text) return null;
  const numStr = text.replace(/[^\d,.]/g, "").replace(",", ".");
  const n = parseFloat(numStr);
  return isNaN(n) ? null : n;
}

module.exports = { fetchEmlakjet };
