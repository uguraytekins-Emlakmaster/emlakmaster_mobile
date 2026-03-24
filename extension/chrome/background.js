/**
 * MV3 service worker — kullanıcı aksiyonunda sekmadan minimal ilan verisi + backend POST.
 * Şifre toplamaz; yalnızca Firebase ID token (storage) ile yetkilendirme.
 */
const DEFAULT_IMPORT_URL =
  "https://europe-west1-YOUR_PROJECT.cloudfunctions.net/extensionImport";

chrome.action.onClicked.addListener(async (tab) => {
  if (!tab?.id || !tab.url) return;
  try {
    const [{ result: listings }] = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => {
        const url = window.location.href;
        const title =
          document.querySelector('meta[property="og:title"]')?.getAttribute("content") ||
          document.title ||
          "";
        const ogImage = document.querySelector('meta[property="og:image"]')?.getAttribute("content") || "";
        const priceText = document.body?.innerText?.match(/(\d{1,3}(?:\.\d{3})+)\s*(?:TL|₺)/i);
        const price = priceText ? parseFloat(priceText[1].replace(/\./g, ""), 10) : null;
        const idMatch = url.match(/(\d{6,})/g);
        const externalListingId = idMatch ? idMatch[idMatch.length - 1] : "";
        if (!title && !externalListingId) return [];
        return [
          {
            title: title.slice(0, 500),
            externalListingId: externalListingId || undefined,
            sourceUrl: url,
            price: Number.isFinite(price) ? price : null,
            images: ogImage ? [ogImage] : [],
          },
        ];
      },
    });

    const { importUrl, idToken, platform } = await chrome.storage.local.get([
      "importUrl",
      "idToken",
      "platform",
    ]);
    const url = importUrl || DEFAULT_IMPORT_URL;
    const plat = platform || detectPlatform(tab.url);
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}),
      },
      body: JSON.stringify({
        listings: Array.isArray(listings) ? listings : [],
        platform: plat,
        importMode: "skip_duplicates",
      }),
    });
    const body = await res.json().catch(() => ({}));
    console.info("Rainbow import", res.status, body);
  } catch (e) {
    console.error("Rainbow import error", e);
  }
});

function detectPlatform(pageUrl) {
  try {
    const h = new URL(pageUrl).hostname;
    if (h.includes("sahibinden")) return "sahibinden";
    if (h.includes("hepsiemlak")) return "hepsiemlak";
    if (h.includes("emlakjet")) return "emlakjet";
  } catch {
    /* ignore */
  }
  return "sahibinden";
}
