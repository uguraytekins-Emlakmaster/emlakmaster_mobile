/**
 * Tek doğruluk kaynağı: `listings` — ofis envanteri (resmi senkron + iç portföy + dosya içe aktarma).
 * Güncelleme yalnızca contentHash değişince (veya ilk yazımda).
 */
const admin = require("firebase-admin");
const crypto = require("crypto");
const { COL_LISTINGS } = require("./constants");

/**
 * @param {string} s
 */
function sanitizeIdPart(s) {
  return String(s || "")
    .replace(/[/#.[\]]/g, "_")
    .replace(/\s+/g, "_")
    .slice(0, 200);
}

/**
 * Deterministic doc id — aynı ofis + platform + kaynak ilan id tek dokümanda birleşir.
 * @param {string} officeId
 * @param {string} sourcePlatform
 * @param {string} sourceListingId
 */
function canonicalListingDocId(officeId, sourcePlatform, sourceListingId) {
  const o = sanitizeIdPart(officeId || "no_office");
  const p = sanitizeIdPart(sourcePlatform);
  const e = sanitizeIdPart(sourceListingId);
  const raw = `own_${o}_${p}_${e}`;
  return raw.length > 1400 ? raw.slice(0, 1400) : raw;
}

/**
 * Normalize alanlar üzerinden hash (dedup / skip no-op updates).
 * @param {object} normalized
 */
function computeContentHash(normalized) {
  const stable = JSON.stringify(normalized, Object.keys(normalized).sort());
  return crypto.createHash("sha256").update(stable, "utf8").digest("hex");
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} params
 * @param {string} params.ownerUserId
 * @param {string} params.officeId
 * @param {string} params.sourcePlatform sahibinden | emlakjet | hepsiemlak | internal | import_csv | …
 * @param {string} params.sourceListingId
 * @param {string} params.title
 * @param {string|number|null} [params.price]
 * @param {string|null} [params.location]
 * @param {string|null} [params.imageUrl]
 * @param {string} [params.syncHash] — önceden hesaplanmış hash (yoksa normalized üretilir)
 * @param {string|null} [params.rawPayloadRef] — Storage yolu veya task referansı
 * @param {string} [params.syncStatus] — synced | pending | error | stale
 */
async function upsertCanonicalOwnedListing(db, params) {
  const {
    ownerUserId,
    officeId,
    sourcePlatform,
    sourceListingId,
    title,
    price,
    location,
    imageUrl,
    syncHash: explicitHash,
    rawPayloadRef,
    syncStatus = "synced",
  } = params;

  if (!ownerUserId || !sourcePlatform || !sourceListingId) {
    throw new Error("upsertCanonicalOwnedListing: ownerUserId, sourcePlatform, sourceListingId zorunlu");
  }

  const normalized = {
    sourcePlatform,
    sourceListingId,
    title: String(title || "").slice(0, 500),
    price: price == null ? null : String(price),
    location: location == null ? null : String(location).slice(0, 300),
    imageUrl: imageUrl == null ? null : String(imageUrl).slice(0, 2000),
  };
  const contentHash = explicitHash || computeContentHash(normalized);

  const docId = canonicalListingDocId(officeId, sourcePlatform, sourceListingId);
  const ref = db.collection(COL_LISTINGS).doc(docId);
  const snap = await ref.get();
  const prev = snap.exists ? snap.data() : null;
  if (prev && prev.contentHash === contentHash) {
    return { docId, unchanged: true, contentHash };
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const priceField = normalized.price != null ? normalized.price : "";

  /** @type {Record<string, unknown>} */
  const payload = {
    ownerUserId,
    officeId: officeId || "",
    title: normalized.title,
    price: priceField,
    location: normalized.location || "",
    imageUrl: normalized.imageUrl || null,
    sourcePlatform,
    sourceListingId,
    isOwnedByOffice: true,
    syncStatus,
    lastSyncedAt: now,
    contentHash,
    rawPayloadRef: rawPayloadRef || null,
    updatedAt: now,
  };

  if (!snap.exists) {
    payload.createdAt = now;
  }

  await ref.set(payload, { merge: true });
  return { docId, unchanged: false, contentHash };
}

module.exports = {
  canonicalListingDocId,
  computeContentHash,
  upsertCanonicalOwnedListing,
};
