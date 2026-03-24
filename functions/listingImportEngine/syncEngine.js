const admin = require("firebase-admin");
const crypto = require("crypto");
const { COL_SYNC_LOGS } = require("./constants");
const { ImportErrorCodes } = require("./errors");
const { upsertIntegrationListing } = require("../integrationListingsAdmin");

const ALLOWED_REMOTE_KEYS = new Set([
  "title",
  "description",
  "price",
  "currency",
  "category",
  "city",
  "district",
  "neighborhood",
  "images",
  "status",
  "sourceUrl",
  "listingType",
]);

/**
 * Manuel senkron — örnek: `integration_listings` kaydı ile uzak JSON hash karşılaştırması.
 * Gerçek OAuth/adapter bağlandığında burada fetch + diff genişletilir.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} params
 * @param {string} params.ownerUserId
 * @param {string} params.listingDocId integration_listings doc id
 * @param {object} params.remoteSnapshot platformdan gelen normalize alanlar
 */
async function runManualListingSync(db, params) {
  const { ownerUserId, listingDocId, remoteSnapshot } = params;
  const ref = db.collection("integration_listings").doc(listingDocId);
  const snap = await ref.get();
  if (!snap.exists) {
    return { state: "failed", errorCode: ImportErrorCodes.SYNC_FAILED, message: "listing_not_found" };
  }
  const local = snap.data();
  if (local.ownerUserId !== ownerUserId) {
    return { state: "failed", errorCode: ImportErrorCodes.PERMISSION_DENIED, message: "owner_mismatch" };
  }

  const filtered = {};
  for (const k of Object.keys(remoteSnapshot || {})) {
    if (ALLOWED_REMOTE_KEYS.has(k)) filtered[k] = remoteSnapshot[k];
  }

  const nextHash = crypto.createHash("sha256").update(JSON.stringify(filtered), "utf8").digest("hex");
  const prevHash = local.syncHash || "";

  if (nextHash === prevHash) {
    const logId = db.collection(COL_SYNC_LOGS).doc().id;
    await db.collection(COL_SYNC_LOGS).doc(logId).set({
      ownerUserId,
      listingDocId,
      state: "success",
      changedFields: [],
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { state: "success", changed: false };
  }

  await upsertIntegrationListing(db, listingDocId, ownerUserId, {
    ...filtered,
    syncHash: nextHash,
    connectionId: local.connectionId,
    platform: local.platform,
    externalListingId: local.externalListingId,
    officeId: local.officeId || "",
  });

  const logId = db.collection(COL_SYNC_LOGS).doc().id;
  await db.collection(COL_SYNC_LOGS).doc(logId).set({
    ownerUserId,
    listingDocId,
    state: "success",
    changedFields: Object.keys(filtered),
    at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { state: "success", changed: true };
}

module.exports = { runManualListingSync };
