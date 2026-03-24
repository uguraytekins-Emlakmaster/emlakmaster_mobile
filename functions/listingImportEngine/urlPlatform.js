const { ImportErrorCodes } = require("./errors");

const SAHIBINDEN_HOSTS = ["sahibinden.com", "www.sahibinden.com"];
const HEPSI_HOSTS = ["hepsiemlak.com", "www.hepsiemlak.com"];
const EMLAKJET_HOSTS = ["emlakjet.com", "www.emlakjet.com"];

/**
 * @param {string} raw
 * @returns {{ ok: boolean, platform?: string, errorCode?: string, hostname?: string }}
 */
function detectPlatformFromUrl(raw) {
  if (typeof raw !== "string" || raw.length < 12) {
    return { ok: false, errorCode: ImportErrorCodes.INVALID_URL };
  }
  let u;
  try {
    u = new URL(raw.trim());
  } catch {
    return { ok: false, errorCode: ImportErrorCodes.INVALID_URL };
  }
  if (u.protocol !== "http:" && u.protocol !== "https:") {
    return { ok: false, errorCode: ImportErrorCodes.INVALID_URL };
  }
  const host = u.hostname.toLowerCase();
  if (SAHIBINDEN_HOSTS.includes(host)) {
    return { ok: true, platform: "sahibinden", hostname: host };
  }
  if (HEPSI_HOSTS.includes(host)) {
    return { ok: true, platform: "hepsiemlak", hostname: host };
  }
  if (EMLAKJET_HOSTS.includes(host)) {
    return { ok: true, platform: "emlakjet", hostname: host };
  }
  return { ok: false, errorCode: ImportErrorCodes.UNSUPPORTED_PLATFORM, hostname: host };
}

/**
 * URL yolundan mümkün olduğunca ilan kimliği çıkarır (platforma özel regex).
 * @param {string} urlStr
 * @param {string} platform sahibinden|hepsiemlak|emlakjet
 * @returns {string|null}
 */
function extractExternalIdFromUrl(urlStr, platform) {
  try {
    const u = new URL(urlStr);
    const path = u.pathname;
    if (platform === "sahibinden") {
      const m = path.match(/(\d{6,})/g);
      if (m && m.length) return m[m.length - 1];
    }
    if (platform === "hepsiemlak") {
      const m = path.match(/(?:ilan|listing)[/-]?([a-zA-Z0-9-]+)/i) || path.match(/(\d{5,})/);
      if (m) return m[1];
    }
    if (platform === "emlakjet") {
      const m = path.match(/(\d{5,})/);
      if (m) return m[1];
    }
  } catch {
    return null;
  }
  return null;
}

module.exports = {
  detectPlatformFromUrl,
  extractExternalIdFromUrl,
};
