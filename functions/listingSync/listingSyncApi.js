/**
 * Callable: ofis için resmi owned listing senkronu (listing_sources + connector'lar).
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { runOfficeSync } = require("./orchestrator");
const { userHasManagerRole } = require("../listingImportEngine/authHelpers");

const REGION = "europe-west1";

function db() {
  return admin.firestore();
}

exports.syncOwnedListingsForOffice = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const uid = context.auth.uid;
    if (!(await userHasManagerRole(db(), uid))) {
      throw new functions.https.HttpsError("permission-denied", "Bu işlem için yönetici yetkisi gerekir.");
    }
    const officeId = typeof data.officeId === "string" ? data.officeId.trim() : "";
    if (!officeId) {
      throw new functions.https.HttpsError("invalid-argument", "officeId gerekli.");
    }
    return runOfficeSync(db(), { officeId, triggeredByUid: uid });
  });
