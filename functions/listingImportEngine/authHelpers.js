const admin = require("firebase-admin");

const MANAGER_ROLES = new Set([
  "super_admin",
  "broker_owner",
  "broker",
  "general_manager",
  "office_manager",
  "team_lead",
  "manager",
  "admin",
  "owner",
]);

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 */
async function userHasManagerRole(db, uid) {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return false;
  const role = snap.data().role;
  return typeof role === "string" && MANAGER_ROLES.has(role);
}

/**
 * @param {string} idToken Firebase ID token (Bearer)
 */
async function verifyBearerAndGetUid(idToken) {
  if (!idToken || typeof idToken !== "string") return null;
  try {
    const dec = await admin.auth().verifyIdToken(idToken);
    return dec.uid;
  } catch {
    return null;
  }
}

module.exports = { userHasManagerRole, verifyBearerAndGetUid, MANAGER_ROLES };
