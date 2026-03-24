const { parseSahibindenListingHtml } = require("./sahibindenParse");
const { parseHepsiemlakListingHtml } = require("./hepsiemlakParse");
const { parseEmlakjetListingHtml } = require("./emlakjetParse");

/**
 * @param {string} platform
 * @param {string} html
 * @param {string} sourceUrl
 */
function parseListingHtml(platform, html, sourceUrl) {
  switch (platform) {
    case "sahibinden":
      return parseSahibindenListingHtml(html, sourceUrl);
    case "hepsiemlak":
      return parseHepsiemlakListingHtml(html, sourceUrl);
    case "emlakjet":
      return parseEmlakjetListingHtml(html, sourceUrl);
    default:
      throw new Error(`unknown_platform:${platform}`);
  }
}

module.exports = { parseListingHtml };
