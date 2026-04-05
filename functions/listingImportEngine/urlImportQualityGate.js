/**
 * URL parse sonrası — kısmi veya güvenilmez çıkarımları üretim envanterine yazmadan durdurur.
 * @param {object} parsed parseListingHtml çıktısı
 * @param {string} platform detectPlatformFromUrl.platform
 * @returns {{ ok: boolean, reason?: string, code?: string }}
 */
function validateUrlImportExtraction(parsed, platform) {
  if (!platform || platform === "unknown") {
    return { ok: false, reason: "PLATFORM", code: "LOW_CONFIDENCE_EXTRACTION" };
  }
  const title = String(parsed.title || "").trim();
  if (title.length < 8) {
    return { ok: false, reason: "TITLE_SHORT", code: "LOW_CONFIDENCE_EXTRACTION" };
  }
  const low = title.toLowerCase();
  const generic = /^(ilan|listing|detail|ılan|undefined|n\/a|null)$/i.test(low);
  if (generic) {
    return { ok: false, reason: "TITLE_GENERIC", code: "LOW_CONFIDENCE_EXTRACTION" };
  }
  const price = parsed.price;
  if (price == null || typeof price !== "number" || !Number.isFinite(price) || price <= 0) {
    return { ok: false, reason: "PRICE", code: "LOW_CONFIDENCE_EXTRACTION" };
  }
  const imgs = Array.isArray(parsed.images) ? parsed.images : [];
  const mainImage = imgs[0];
  if (!mainImage || String(mainImage).trim().length < 8) {
    return { ok: false, reason: "IMAGE", code: "LOW_CONFIDENCE_EXTRACTION" };
  }
  const city = parsed.city != null ? String(parsed.city).trim() : "";
  const district = parsed.district != null ? String(parsed.district).trim() : "";
  const hasStructuredLoc = city.length > 1 || district.length > 1;
  const locHint = /(İstanbul|Ankara|İzmir|Bursa|Antalya|Adana|Konya|Gaziantep|Diyarbakır|Kayapınar|Merkez|Yenişehir|Bağlar|Çankaya|Kadıköy)/i.test(
    title
  );
  if (!hasStructuredLoc && !locHint) {
    return { ok: false, reason: "LOCATION", code: "LOW_CONFIDENCE_EXTRACTION" };
  }
  return { ok: true };
}

module.exports = { validateUrlImportExtraction };
