const axios = require("axios");

const DEFAULT_UA =
  "Mozilla/5.0 (compatible; RainbowCRM-ImportBot/1.0; +https://example.invalid/bot) AppleWebKit/537.36";

/**
 * @param {string} url
 * @param {{ timeoutMs?: number }} opts
 * @returns {Promise<{ ok: boolean, html?: string, status?: number, error?: string }>}
 */
async function fetchListingHtml(url, opts = {}) {
  const timeoutMs = opts.timeoutMs ?? 18000;
  try {
    const res = await axios.get(url, {
      timeout: timeoutMs,
      maxRedirects: 5,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        "User-Agent": DEFAULT_UA,
        Accept: "text/html,application/xhtml+xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.5",
      },
      responseType: "text",
    });
    return { ok: true, html: typeof res.data === "string" ? res.data : String(res.data), status: res.status };
  } catch (e) {
    const msg = e.response ? `http_${e.response.status}` : String(e.message || e);
    return { ok: false, error: msg };
  }
}

module.exports = { fetchListingHtml };
