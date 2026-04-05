/**
 * Resmi API / feed / partner köprüsü — ortam değişkenleri yoksa boş döner (scraping yok).
 */

const { fetchSahibindenOfficial } = require("./officialSahibinden");
const { fetchEmlakjetOfficial } = require("./officialEmlakjet");
const { fetchHepsiemlakOfficial } = require("./officialHepsiemlak");

const HANDLERS = {
  sahibinden: fetchSahibindenOfficial,
  emlakjet: fetchEmlakjetOfficial,
  hepsiemlak: fetchHepsiemlakOfficial,
};

/**
 * @param {string} platform sahibinden | emlakjet | hepsiemlak
 * @param {object} ctx
 * @param {FirebaseFirestore.Firestore} ctx.db
 * @param {string} ctx.officeId
 * @param {string} ctx.connectionId
 * @param {string} ctx.ownerUserId
 */
async function runConnector(platform, ctx) {
  const fn = HANDLERS[platform];
  if (!fn) {
    return {
      items: [],
      mode: "unsupported",
      message: `Platform için resmi connector tanımlı değil: ${platform}`,
    };
  }
  return fn(ctx);
}

module.exports = {
  runConnector,
  HANDLERS,
};
