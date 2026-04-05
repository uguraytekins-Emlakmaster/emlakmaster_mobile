/**
 * Sahibinden — yalnızca onaylı resmi API / transfer uçları.
 * SAHIBINDEN_OFFICIAL_API_BASE_URL + SAHIBINDEN_OFFICIAL_API_TOKEN (veya partner sözleşmesindeki alanlar) olmadan veri dönmez.
 */

/**
 * @param {object} ctx
 * @param {FirebaseFirestore.Firestore} ctx.db
 * @param {string} ctx.officeId
 * @param {string} ctx.connectionId
 * @param {string} ctx.ownerUserId
 */
async function fetchSahibindenOfficial(ctx) {
  const baseUrl = process.env.SAHIBINDEN_OFFICIAL_API_BASE_URL || "";
  const token = process.env.SAHIBINDEN_OFFICIAL_API_TOKEN || "";
  if (!baseUrl || !token) {
    return {
      items: [],
      mode: "not_configured",
      message:
        "Sahibinden resmi API yapılandırılmadı (SAHIBINDEN_OFFICIAL_API_BASE_URL / SAHIBINDEN_OFFICIAL_API_TOKEN).",
    };
  }

  // Üretim: HTTPS GET/POST ile ilan listesi — yanıt şeması partner dokümantasyonuna göre map edilir.
  void ctx;
  return {
    items: [],
    mode: "official_api",
    message: "Connector hazır; yanıt şeması partner entegrasyonunda tamamlanacak.",
  };
}

module.exports = { fetchSahibindenOfficial };
