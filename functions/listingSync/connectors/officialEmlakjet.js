/**
 * Emlakjet — resmi feed / API / import köprüsü (scraping yok).
 */

/**
 * @param {object} ctx
 */
async function fetchEmlakjetOfficial(ctx) {
  const baseUrl = process.env.EMLAKJET_OFFICIAL_API_BASE_URL || "";
  const token = process.env.EMLAKJET_OFFICIAL_API_TOKEN || "";
  if (!baseUrl || !token) {
    return {
      items: [],
      mode: "not_configured",
      message:
        "Emlakjet resmi API yapılandırılmadı (EMLAKJET_OFFICIAL_API_BASE_URL / EMLAKJET_OFFICIAL_API_TOKEN).",
    };
  }
  void ctx;
  return {
    items: [],
    mode: "official_api",
    message: "Connector hazır; yanıt şeması partner entegrasyonunda tamamlanacak.",
  };
}

module.exports = { fetchEmlakjetOfficial };
