/**
 * Hepsiemlak — resmi feed / API / import köprüsü (scraping yok).
 */

/**
 * @param {object} ctx
 */
async function fetchHepsiemlakOfficial(ctx) {
  const baseUrl = process.env.HEPSIEMLAK_OFFICIAL_API_BASE_URL || "";
  const token = process.env.HEPSIEMLAK_OFFICIAL_API_TOKEN || "";
  if (!baseUrl || !token) {
    return {
      items: [],
      mode: "not_configured",
      message:
        "Hepsiemlak resmi API yapılandırılmadı (HEPSIEMLAK_OFFICIAL_API_BASE_URL / HEPSIEMLAK_OFFICIAL_API_TOKEN).",
    };
  }
  void ctx;
  return {
    items: [],
    mode: "official_api",
    message: "Connector hazır; yanıt şeması partner entegrasyonunda tamamlanacak.",
  };
}

module.exports = { fetchHepsiemlakOfficial };
