const axios = require("axios");
const cheerio = require("cheerio");

/**
 * hepsi emlak – son ilanlar (site URL yapısına göre güncellenir).
 */
async function fetchHepsiEmlak(cityCode, cityName, districtName) {
  const out = [];
  try {
    const baseUrl = "https://www.hepsiemlak.com";
    const citySlug = cityName.toLowerCase().replace(/ğ/g, "g").replace(/ü/g, "u").replace(/ş/g, "s").replace(/ı/g, "i").replace(/ö/g, "o").replace(/ç/g, "c");
    const url = `${baseUrl}/satilik/${citySlug}`;
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
    $("a[href*='/ilan/'], .listing a, .card a").each((i, el) => {
      const $el = $(el);
      const href = $el.attr("href");
      if (!href) return;
      const fullLink = href.startsWith("http") ? href : `${baseUrl}${href}`;
      const title = $el.find("h2, h3, .title").first().text().trim() || $el.text().trim().slice(0, 100);
      const priceText = $el.find(".price").first().text().trim();
      const externalId = fullLink.split("/").filter(Boolean).pop() || `he-${Date.now()}-${i}`;
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
    console.warn("hepsiEmlak fetch error", e.message);
  }
  return out.slice(0, 20);
}

function parsePrice(text) {
  if (!text) return null;
  const numStr = text.replace(/[^\d,.]/g, "").replace(",", ".");
  const n = parseFloat(numStr);
  return isNaN(n) ? null : n;
}

module.exports = { fetchHepsiEmlak };
