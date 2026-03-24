const crypto = require("crypto");
const { COL_INTEGRATION_LISTINGS } = require("../integrationListingsAdmin");

/**
 * @param {string} title
 * @param {number|null} price
 * @param {string|null} city
 * @param {string|null} district
 */
function buildDuplicateFingerprint(title, price, city, district) {
  const norm = (s) =>
    String(s || "")
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/\s+/g, " ")
      .trim();
  const raw = `${norm(title)}|${price ?? ""}|${norm(city)}|${norm(district)}`;
  return crypto.createHash("sha256").update(raw, "utf8").digest("hex");
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} ownerUserId
 * @param {string} platform
 * @param {string} externalListingId
 */
async function findByExternalId(db, ownerUserId, platform, externalListingId) {
  if (!externalListingId || externalListingId.length < 2) return null;
  const q = await db
    .collection(COL_INTEGRATION_LISTINGS)
    .where("ownerUserId", "==", ownerUserId)
    .where("platform", "==", platform)
    .where("externalListingId", "==", externalListingId)
    .limit(1)
    .get();
  return q.empty ? null : q.docs[0];
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} ownerUserId
 * @param {string} platform
 * @param {string} fingerprint
 */
async function findByFingerprint(db, ownerUserId, platform, fingerprint) {
  if (!fingerprint) return null;
  const q = await db
    .collection(COL_INTEGRATION_LISTINGS)
    .where("ownerUserId", "==", ownerUserId)
    .where("platform", "==", platform)
    .where("duplicateFingerprint", "==", fingerprint)
    .limit(1)
    .get();
  return q.empty ? null : q.docs[0];
}

/**
 * Aynı kaydı veya fingerprint eşleşmesini döndürür.
 */
async function findDuplicateListing(db, ownerUserId, platform, externalListingId, fingerprint) {
  const byExt = await findByExternalId(db, ownerUserId, platform, externalListingId);
  if (byExt) return { doc: byExt, reason: "external_id" };
  const byFp = await findByFingerprint(db, ownerUserId, platform, fingerprint);
  if (byFp) return { doc: byFp, reason: "fingerprint" };
  return null;
}

function makeDocId(connectionId, platform, externalListingId) {
  const safe = (s) => String(s || "").replace(/[/.#\s]/g, "_");
  const base = `${safe(connectionId)}_${safe(platform)}_${safe(externalListingId)}`.slice(0, 700);
  return base || `listing_${crypto.randomBytes(12).toString("hex")}`;
}

module.exports = {
  buildDuplicateFingerprint,
  findByExternalId,
  findByFingerprint,
  findDuplicateListing,
  makeDocId,
};
