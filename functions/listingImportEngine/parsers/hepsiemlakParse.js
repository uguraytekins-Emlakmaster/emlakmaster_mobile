const cheerio = require("cheerio");
const { extractExternalIdFromUrl } = require("../urlPlatform");

function parseHepsiemlakListingHtml(html, sourceUrl) {
  const $ = cheerio.load(html);
  const title =
    $('meta[property="og:title"]').attr("content") ||
    $("title").first().text() ||
    "";
  const desc =
    $('meta[property="og:description"]').attr("content") ||
    $('meta[name="description"]').attr("content") ||
    "";
  const image = $('meta[property="og:image"]').attr("content");
  const images = image ? [image] : [];

  let price = null;
  const bodyText = $("body").text().replace(/\s+/g, " ");
  const pm = bodyText.match(/(\d{1,3}(?:\.\d{3})+)\s*(?:TL|₺)/i);
  if (pm) {
    price = parseFloat(pm[1].replace(/\./g, "")) || null;
  }

  let externalId = extractExternalIdFromUrl(sourceUrl, "hepsiemlak");
  const partial = !title || title.length < 3;

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

module.exports = { parseHepsiemlakListingHtml };
