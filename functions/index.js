const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { fetchSahibinden } = require("./fetchers/sahibinden");
const { fetchEmlakjet } = require("./fetchers/emlakjet");
const { fetchHepsiEmlak } = require("./fetchers/hepsiEmlak");
const { rollupMarketIntelligence } = require("./rollupMarketPulse");

admin.initializeApp();

const DB = admin.firestore();
const COL_SETTINGS = "app_settings";
const DOC_LISTING_DISPLAY = "listing_display_settings";
const COL_EXTERNAL_LISTINGS = "external_listings";

/**
 * SCRAPER_MODE (Functions ortam değişkeni veya .env):
 * - hybrid: doğrudan HTML dene + rollup (varsayılan)
 * - ingest_only: sadece ingest webhook + rollup; Cloudflare korumalı sitelere CF sunucudan gitmez
 * - direct_only: sadece doğrudan çekim (test)
 */
function getScraperMode() {
  return (process.env.SCRAPER_MODE || "hybrid").toLowerCase();
}

/** Ingest güvenliği: x-ingest-secret veya INGEST_SECRET ortam değişkeni */
function getIngestSecret() {
  return process.env.INGEST_SECRET || "";
}

/** Ayarlardan şehir bilgisini al */
async function getListingDisplaySettings() {
  const ref = DB.collection(COL_SETTINGS).doc(DOC_LISTING_DISPLAY);
  const snap = await ref.get();
  if (!snap.exists) {
    return { cityCode: "21", cityName: "Diyarbakır", districtName: null };
  }
  const d = snap.data();
  return {
    cityCode: d.cityCode || "21",
    cityName: d.cityName || "Diyarbakır",
    districtName: d.districtName || null,
  };
}

/** Tek bir ilanı Firestore formatında döndür (id = source_externalId) */
function toFirestoreListing(item, source, cityCode, cityName) {
  const id = `${source}_${item.externalId}`.replace(/[/.#]/g, "_");
  return {
    id,
    source,
    externalId: item.externalId,
    title: item.title || "",
    priceText: item.priceText || null,
    priceValue: item.priceValue ?? null,
    cityCode,
    cityName,
    districtName: item.district || null,
    link: item.link || "",
    imageUrl: item.imageUrl || null,
    postedAt: item.postedAt ? admin.firestore.Timestamp.fromDate(item.postedAt) : admin.firestore.Timestamp.now(),
    roomCount: item.roomCount || null,
    sqm: item.sqm ?? null,
  };
}

/** Tüm kaynaklardan ilan çek, Firestore'a yaz (dedupe by id) */
async function fetchAndWriteListings() {
  const settings = await getListingDisplaySettings();
  const { cityCode, cityName, districtName } = settings;
  const all = [];
  try {
    const [sahibindenList, emlakjetList, hepsiList] = await Promise.allSettled([
      fetchSahibinden(cityCode, cityName, districtName),
      fetchEmlakjet(cityCode, cityName, districtName),
      fetchHepsiEmlak(cityCode, cityName, districtName),
    ]);
    if (sahibindenList.status === "fulfilled" && Array.isArray(sahibindenList.value)) {
      all.push(...sahibindenList.value.map((i) => toFirestoreListing(i, "sahibinden", cityCode, cityName)));
    }
    if (emlakjetList.status === "fulfilled" && Array.isArray(emlakjetList.value)) {
      all.push(...emlakjetList.value.map((i) => toFirestoreListing(i, "emlakjet", cityCode, cityName)));
    }
    if (hepsiList.status === "fulfilled" && Array.isArray(hepsiList.value)) {
      all.push(...hepsiList.value.map((i) => toFirestoreListing(i, "hepsiEmlak", cityCode, cityName)));
    }
  } catch (e) {
    functions.logger.warn("fetchAndWriteListings error", e);
  }
  if (all.length === 0) return 0;
  const col = DB.collection(COL_EXTERNAL_LISTINGS);
  const batch = admin.firestore().batch();
  const seen = new Set();
  for (const doc of all) {
    if (seen.has(doc.id)) continue;
    seen.add(doc.id);
    const { id, ...data } = doc;
    batch.set(col.doc(id), data, { merge: true });
  }
  await batch.commit();
  functions.logger.info(`Written ${seen.size} external listings for ${cityName}`);
  return seen.size;
}

/**
 * FlareSolverr / Selenium / ücretli proxy worker'ınızdan gelen normalize JSON ile doldurur.
 * Body: { "listings": [ { externalId, title, priceValue, link, districtName, ... } ] }
 */
async function ingestListingsFromBody(body, cityCode, cityName) {
  const listings = body && Array.isArray(body.listings) ? body.listings : [];
  if (listings.length === 0) return 0;
  const col = DB.collection(COL_EXTERNAL_LISTINGS);
  let n = 0;
  const batch = DB.batch();
  const max = 400;
  const slice = listings.slice(0, max);
  for (const raw of slice) {
    const externalId = String(raw.externalId || raw.id || "").trim();
    if (!externalId) continue;
    const source = String(raw.source || "pipeline").replace(/[/.#]/g, "_");
    const id = `${source}_${externalId}`.replace(/[/.#]/g, "_");
    let postedAt = admin.firestore.Timestamp.now();
    if (raw.postedAt) {
      const d = new Date(raw.postedAt);
      if (!Number.isNaN(d.getTime())) postedAt = admin.firestore.Timestamp.fromDate(d);
    }
    const priceValue =
      typeof raw.priceValue === "number"
        ? raw.priceValue
        : parseFloat(String(raw.priceValue || "").replace(/\./g, "").replace(",", ".")) || null;
    batch.set(
      col.doc(id),
      {
        source,
        externalId,
        title: raw.title || "",
        priceText: raw.priceText || null,
        priceValue,
        cityCode,
        cityName,
        districtName: raw.districtName || raw.district || null,
        link: raw.link || "",
        imageUrl: raw.imageUrl || null,
        postedAt,
        clientFetched: false,
        ingestedBy: "cloud_function",
        ingestedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    n++;
  }
  if (n > 0) await batch.commit();
  return n;
}

/**
 * 6 saatte bir (pil / kota dostu): doğrudan HTML çekim (moda göre) + Firestore rollup.
 * Önceki 15 dk.lık schedule yerine tek düşük frekanslı iş.
 */
exports.scheduledFetchListings = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .pubsub.schedule("every 6 hours")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const mode = getScraperMode();
    let written = 0;
    if (mode !== "ingest_only") {
      written = await fetchAndWriteListings();
    } else {
      functions.logger.info("scheduledFetchListings: SCRAPER_MODE=ingest_only, skip direct fetch");
    }
    await rollupMarketIntelligence(DB);
    return { written, rollup: true };
  });

/** Manuel: çek + rollup */
exports.fetchListingsNow = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const mode = getScraperMode();
    let written = 0;
    if (mode !== "ingest_only") {
      written = await fetchAndWriteListings();
    }
    await rollupMarketIntelligence(DB);
    return { ok: true, written, mode };
  });

/**
 * Harici worker (FlareSolverr, ücretsiz VPS) POST ile JSON gönderir.
 * Header: x-ingest-secret: <INGEST_SECRET>
 */
exports.ingestListingsPipeline = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .https.onRequest(async (req, res) => {
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST");
      res.set("Access-Control-Allow-Headers", "Content-Type, x-ingest-secret");
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method_not_allowed" });
      return;
    }
    const secret = getIngestSecret();
    if (!secret || req.get("x-ingest-secret") !== secret) {
      res.status(401).json({ ok: false, error: "unauthorized" });
      return;
    }
    try {
      const settings = await getListingDisplaySettings();
      const n = await ingestListingsFromBody(req.body, settings.cityCode, settings.cityName);
      await rollupMarketIntelligence(DB);
      res.json({ ok: true, ingested: n });
    } catch (e) {
      functions.logger.error("ingestListingsPipeline", e);
      res.status(500).json({ ok: false, error: String(e.message || e) });
    }
  });

// ---------------------------------------------------------------------------
// Core Import Engine — URL / dosya / uzantı / senkron / yönetici onayı
// ---------------------------------------------------------------------------
const listingImportApi = require("./listingImportEngine/listingImportApi");
exports.enqueueUrlImport = listingImportApi.enqueueUrlImport;
exports.enqueueFileImport = listingImportApi.enqueueFileImport;
exports.onListingImportTaskCreated = listingImportApi.onListingImportTaskCreated;
exports.extensionImport = listingImportApi.extensionImport;
exports.adminApproveImportTask = listingImportApi.adminApproveImportTask;
exports.runIntegrationListingSync = listingImportApi.runIntegrationListingSync;

// Uzak AI callable — kota, kill switch, idempotency (aiRemoteGuard.js)
const aiCallables = require("./aiCallables");
exports.enrichPostCallSummary = aiCallables.enrichPostCallSummary;
exports.generateBulkCampaignMessage = aiCallables.generateBulkCampaignMessage;
