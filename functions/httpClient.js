/**
 * Ortak HTTP istemcisi: isteğe bağlı HTTP(S) proxy (Bright Data / Zyte / kurumsal gateway).
 * Cloudflare aşmak için tek başına yetmez; residential proxy veya FlareSolverr + tarayıcı gerekir.
 *
 * Ortam:
 * - HTTPS_PROXY veya HTTP_PROXY: örn. http://user:pass@host:port
 */
const axios = require("axios");
const { HttpsProxyAgent } = require("https-proxy-agent");
const { HttpProxyAgent } = require("http-proxy-agent");

let _cached;

function getAxios() {
  if (_cached) return _cached;
  const proxyUrl = process.env.HTTPS_PROXY || process.env.HTTP_PROXY || "";
  if (!proxyUrl) {
    _cached = axios;
    return _cached;
  }
  try {
    const httpsAgent = new HttpsProxyAgent(proxyUrl);
    const httpAgent = new HttpProxyAgent(proxyUrl);
    _cached = axios.create({
      httpAgent,
      httpsAgent,
      proxy: false,
      timeout: 20000,
    });
    return _cached;
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn("httpClient: proxy parse failed, using default axios", e.message);
    _cached = axios;
    return _cached;
  }
}

module.exports = { getAxios };
