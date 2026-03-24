const cheerio = require("cheerio");
const { extractExternalIdFromUrl } = require("../urlPlatform");

/**
 * Meta + JSON-LD + yaygın sınıflar — sayfa yapısı değişirse partial döner.
 * @param {string} html
 * @param {string} sourceUrl
 */
function parseSahibindenListingHtml(html, sourceUrl) {
  const $ = cheerio.load(html);
  const title =
    $('meta[property="og:title"]').attr("content") ||
    $("title").first().text() ||
    "";
  const desc =
    $('meta[property="og:description"]').attr("content") ||
    $('meta[name="description"]').attr("content") ||
    "";
  let image =
    $('meta[property="og:image"]').attr("content") || $('link[rel="image_src"]').attr("href") || null;

  const images = [];
  if (image) images.push(image);
  $('script[type="application/ld+json"]').each((_, el) => {
    try {
      const txt = $(el).html();
      if (!txt) return;
      const j = JSON.parse(txt);
      const nodes = Array.isArray(j) ? j : [j];
      for (const node of nodes) {
        if (node["@type"] === "Product" || node["@type"] === "SingleFamilyResidence") {
          if (node.image) {
            const im = Array.isArray(node.image) ? node.image[0] : node.image;
            if (typeof im === "string" && !images.includes(im)) images.push(im);
          }
          if (node.offers && node.offers.price) {
            // handled below
          }
        }
      }
    } catch {
      /* ignore */
    }
  });

  let price = null;
  const bodyText = $("body").text().replace(/\s+/g, " ");
  const priceMatch = bodyText.match(/(\d{1,3}(?:\.\d{3})+)\s*(?:TL|₺)/i);
  if (priceMatch) {
    const n = priceMatch[1].replace(/\./g, "");
    price = parseFloat(n) || null;
  }
  const dataPrice = $("[data-price]").attr("data-price");
  if (dataPrice && !price) {
    const p = parseFloat(String(dataPrice).replace(/\./g, ""));
    if (!Number.isNaN(p)) price = p;
  }

  let externalId = extractExternalIdFromUrl(sourceUrl, "sahibinden");
  const cls = $(".classifiedId, #classifiedId, [data-classifiedid]").first().text().trim();
  if (cls && /^\d+$/.test(cls)) externalId = cls;

  const partial =
    !title ||
    title.length < 3 ||
    (!price && !image);

  return {
    externalListingId: externalId || null,
    title: title.trim().slice(0, 500),
    description: desc ? desc.trim().slice(0, 8000) : null,
    price,
    currency: "TRY",
    city: null,
    district: null,
    category: null,
    images: images.slice(0, 24),
    partial,
  };
}

module.exports = { parseSahibindenListingHtml };
