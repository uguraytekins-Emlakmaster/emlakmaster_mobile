/**
 * Firestore external_listings üzerinden bölge medyan fiyatı ve "fırsat" keşiflerini hesaplar;
 * analytics_daily (heatmap_*, discovery_*) dokümanlarına yazar.
 * Uygulama yalnızca snapshot dinler — pil dostu.
 */
const admin = require("firebase-admin");
const functions = require("firebase-functions");

const COL_ANALYTICS = "analytics_daily";
const COL_EXTERNAL = "external_listings";
const COL_SETTINGS = "app_settings";
const DOC_LISTING_DISPLAY = "listing_display_settings";

/** Diyarbakır ilçe → Market Pulse regionId */
function inferRegionId(districtName) {
  if (!districtName || typeof districtName !== "string") return "yenisehir";
  const n = districtName
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g");
  if (n.includes("kayapinar")) return "kayapinar";
  if (n.includes("baglar")) return "baglar";
  if (n.includes("yenisehir")) return "yenisehir";
  return "yenisehir";
}

const REGION_META = {
  kayapinar: { regionName: "Kayapınar", budgetSegment: "4M-6M", propertyTypeHint: "3+1" },
  baglar: { regionName: "Bağlar", budgetSegment: "2M-4M", propertyTypeHint: "arsa" },
  yenisehir: { regionName: "Yenişehir", budgetSegment: "3M-5M", propertyTypeHint: "2+1" },
};

function median(nums) {
  if (!nums.length) return 0;
  const s = [...nums].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

async function getListingDisplaySettings(db) {
  const ref = db.collection(COL_SETTINGS).doc(DOC_LISTING_DISPLAY);
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

async function getPipelineConfig(db) {
  const ref = db.collection(COL_SETTINGS).doc("intelligence_pipeline");
  const snap = await ref.get();
  const d = snap.exists ? snap.data() : {};
  const ratio = typeof d.opportunityPriceRatio === "number" ? d.opportunityPriceRatio : 0.85;
  return {
    opportunityPriceRatio: Math.min(0.99, Math.max(0.5, ratio)),
  };
}

/**
 * @param {FirebaseFirestore.Firestore} db
 */
async function rollupMarketIntelligence(db) {
  const settings = await getListingDisplaySettings(db);
  const { opportunityPriceRatio } = await getPipelineConfig(db);
  const { cityCode } = settings;

  const snap = await db
    .collection(COL_EXTERNAL)
    .where("cityCode", "==", cityCode)
    .limit(500)
    .get();

  const byRegion = { kayapinar: [], baglar: [], yenisehir: [] };
  const rows = [];

  snap.forEach((doc) => {
    const x = doc.data();
    const pv = typeof x.priceValue === "number" ? x.priceValue : 0;
    if (pv <= 0) return;
    const rid = inferRegionId(x.districtName);
    if (!byRegion[rid]) byRegion[rid] = [];
    byRegion[rid].push(pv);
    rows.push({
      id: doc.id,
      title: x.title || "İlan",
      districtName: x.districtName || "",
      priceValue: pv,
      link: x.link || "",
      regionId: rid,
    });
  });

  const date = new Date().toISOString().substring(0, 10);
  const now = admin.firestore.Timestamp.now();

  // Heatmap: talep skoru = ilan yoğunluğuna göre (0.55–0.92)
  const heatmap = ["kayapinar", "baglar", "yenisehir"].map((rid) => {
    const prices = byRegion[rid] || [];
    const n = prices.length;
    const demandScore = n === 0 ? 0.58 : Math.min(0.92, 0.55 + Math.min(n, 80) / 200);
    const meta = REGION_META[rid];
    return {
      regionId: rid,
      regionName: meta.regionName,
      demandScore,
      budgetSegment: meta.budgetSegment,
      propertyTypeHint: meta.propertyTypeHint,
      computedAt: now,
    };
  });

  const discoveryItems = [];
  for (const rid of Object.keys(byRegion)) {
    const prices = byRegion[rid];
    if (prices.length < 3) continue;
    const med = median(prices);
    if (med <= 0) continue;
    const threshold = med * opportunityPriceRatio;
    for (const row of rows) {
      if (row.regionId !== rid) continue;
      if (row.priceValue >= threshold) continue;
      // Skor: medyana göre ne kadar ucuz (0.80 – 0.98)
      const raw = 0.8 + (1 - row.priceValue / med) * 0.35;
      const score = Math.min(0.98, Math.max(0.8, raw));
      discoveryItems.push({
        id: `opp_${row.id}_${date}`,
        type: "hidden_opportunity",
        listingId: row.id,
        title: row.title,
        subtitle: `${REGION_META[rid].regionName}: medyan ${Math.round(med).toLocaleString("tr-TR")} ₺ altı`,
        score,
        highlights: [
          `Medyanın ~%${Math.round(opportunityPriceRatio * 100)} altında`,
          "Sunucu rollup (Cloud Functions)",
        ],
        computedAt: now,
      });
    }
  }

  // En fazla 25 kayıt (Firestore boyutu + UI)
  discoveryItems.sort((a, b) => b.score - a.score);
  const top = discoveryItems.slice(0, 25);

  const batch = db.batch();
  const heatRef = db.collection(COL_ANALYTICS).doc(`heatmap_${date}`);
  const discRef = db.collection(COL_ANALYTICS).doc(`discovery_${date}`);

  batch.set(
    heatRef,
    {
      date,
      regions: heatmap,
      computedAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "cloud_functions_rollup",
      rollupStats: {
        listingSampleSize: snap.size,
        opportunityCount: top.length,
      },
    },
    { merge: true }
  );

  batch.set(
    discRef,
    {
      date,
      items: top.map((e) => ({
        id: e.id,
        type: e.type,
        listingId: e.listingId,
        title: e.title,
        subtitle: e.subtitle,
        score: e.score,
        highlights: e.highlights,
        computedAt: e.computedAt,
      })),
      computedAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "cloud_functions_rollup",
    },
    { merge: true }
  );

  await batch.commit();
  functions.logger.info("rollupMarketIntelligence", {
    cityCode,
    listings: snap.size,
    opportunities: top.length,
  });
}

module.exports = { rollupMarketIntelligence, inferRegionId };
