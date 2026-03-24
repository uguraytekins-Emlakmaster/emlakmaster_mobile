/**
 * integration_listings — yalnızca Admin SDK (Cloud Functions / backend) ile yazılır.
 * İstemci kuralları: create/update/delete kapalı; okuma ownerUserId veya yönetici.
 *
 * Rainbow CRM / OAuth senkron işi bu modülü veya aynı şemayı kullanmalıdır.
 */
const admin = require("firebase-admin");

const COL_INTEGRATION_LISTINGS = "integration_listings";

const PLATFORMS = new Set(["sahibinden", "hepsiemlak", "emlakjet"]);

/**
 * @param {string} ownerUserId Firebase Auth UID (zorunlu — mobil uygulama sorgusu buna göre)
 * @param {object} fields Diğer alanlar (connectionId, platform, externalListingId, title, …)
 * @returns {object} Firestore merge/set için data
 */
function buildIntegrationListingPayload(ownerUserId, fields) {
  if (typeof ownerUserId !== "string" || ownerUserId.length < 10) {
    throw new Error("integration_listings: ownerUserId (Firebase Auth uid) zorunlu");
  }
  const platform = fields.platform;
  if (!PLATFORMS.has(platform)) {
    throw new Error(`integration_listings: platform geçersiz: ${platform}`);
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  return {
    ownerUserId,
    connectionId: String(fields.connectionId || ""),
    platform,
    externalListingId: String(fields.externalListingId || ""),
    internalListingId: fields.internalListingId ?? null,
    title: String(fields.title || ""),
    description: fields.description ?? null,
    price: typeof fields.price === "number" ? fields.price : null,
    currency: fields.currency ?? "TRY",
    listingType: fields.listingType ?? null,
    category: fields.category ?? null,
    city: fields.city ?? null,
    district: fields.district ?? null,
    neighborhood: fields.neighborhood ?? null,
    images: Array.isArray(fields.images) ? fields.images : [],
    status: fields.status ?? null,
    sourceUrl: String(fields.sourceUrl || ""),
    platformUpdatedAt: fields.platformUpdatedAt || null,
    importedAt: fields.importedAt || now,
    syncedAt: now,
    syncHash: fields.syncHash ?? null,
    officeId: String(fields.officeId || ""),
    /** Duplicate engine: başlık+fiyat+konum hash (title+price+city+district) */
    duplicateFingerprint: fields.duplicateFingerprint ?? null,
    /** Aynı mülkün birden fazla kaynağı — gruplama anahtarı (ilk kayıt doc id) */
    duplicateGroupId: fields.duplicateGroupId ?? null,
    linkedDuplicateOf: fields.linkedDuplicateOf ?? null,
    /** İç CRM ilanı (listings) ile bağlantı — Phase 1 alanı */
    canonicalListingId: fields.canonicalListingId ?? null,
    syncStatus: fields.syncStatus ?? null,
    rawPayload: fields.rawPayload && typeof fields.rawPayload === "object" ? fields.rawPayload : null,
    updatedAt: now,
  };
}

/**
 * Tekil ilan upsert (docId: örn. `${connectionId}_${externalListingId}` — özel karakterler temizlenmiş).
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} docId
 * @param {string} ownerUserId
 * @param {object} fields
 */
async function upsertIntegrationListing(db, docId, ownerUserId, fields) {
  const data = buildIntegrationListingPayload(ownerUserId, fields);
  await db.collection(COL_INTEGRATION_LISTINGS).doc(docId).set(data, { merge: true });
}

module.exports = {
  COL_INTEGRATION_LISTINGS,
  buildIntegrationListingPayload,
  upsertIntegrationListing,
};
