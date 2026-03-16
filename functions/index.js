const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { fetchSahibinden } = require("./fetchers/sahibinden");
const { fetchEmlakjet } = require("./fetchers/emlakjet");
const { fetchHepsiEmlak } = require("./fetchers/hepsiEmlak");

admin.initializeApp();

const DB = admin.firestore();
const COL_SETTINGS = "app_settings";
const DOC_LISTING_DISPLAY = "listing_display_settings";
const COL_EXTERNAL_LISTINGS = "external_listings";

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
  if (all.length === 0) return;
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
}

/** Her 15 dakikada bir çalışır */
exports.scheduledFetchListings = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .pubsub.schedule("every 15 minutes")
  .onRun(async () => {
    await fetchAndWriteListings();
  });

/** Manuel tetikleme (HTTP callable) */
exports.fetchListingsNow = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .https.onCall(async () => {
    await fetchAndWriteListings();
    return { ok: true };
  });
