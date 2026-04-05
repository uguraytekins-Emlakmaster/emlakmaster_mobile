const admin = require("firebase-admin");
const { COL_LISTING_SYNC_RUNS, COL_LISTING_SYNC_ERRORS } = require("./constants");

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} p
 * @param {string} p.officeId
 * @param {string} p.platform
 * @param {string} p.connectorType
 * @param {string} [p.listingSourceId]
 * @param {string} [p.triggeredByUid]
 */
async function beginSyncRun(db, p) {
  const ref = db.collection(COL_LISTING_SYNC_RUNS).doc();
  await ref.set({
    officeId: p.officeId,
    platform: p.platform,
    connectorType: p.connectorType,
    listingSourceId: p.listingSourceId || null,
    triggeredByUid: p.triggeredByUid || null,
    status: "running",
    startedAt: admin.firestore.FieldValue.serverTimestamp(),
    stats: {
      fetched: 0,
      upserted: 0,
      skippedUnchanged: 0,
      errors: 0,
    },
  });
  return ref.id;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} runId
 * @param {object} p
 * @param {'success'|'failed'|'partial'} p.status
 * @param {object} p.stats
 * @param {string} [p.message]
 */
async function finishSyncRun(db, runId, p) {
  await db
    .collection(COL_LISTING_SYNC_RUNS)
    .doc(runId)
    .set(
      {
        status: p.status,
        finishedAt: admin.firestore.FieldValue.serverTimestamp(),
        stats: p.stats,
        message: p.message || null,
      },
      { merge: true }
    );
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} p
 */
async function recordSyncError(db, p) {
  const ref = db.collection(COL_LISTING_SYNC_ERRORS).doc();
  await ref.set({
    runId: p.runId,
    officeId: p.officeId,
    platform: p.platform,
    code: p.code,
    message: String(p.message || "").slice(0, 2000),
    at: admin.firestore.FieldValue.serverTimestamp(),
    listingSourceId: p.listingSourceId || null,
  });
}

module.exports = {
  beginSyncRun,
  finishSyncRun,
  recordSyncError,
};
