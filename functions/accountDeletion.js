const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * Hesap silme veri temizliği (KVKK / App Store "hesabı sil" zorunluluğu).
 *
 * Firebase Auth hesabı silindiğinde (uygulama içi "Hesabı kalıcı sil" akışı
 * `user.delete()` çağırır) tetiklenir ve kullanıcıya ait Firestore verilerini
 * sunucu tarafında temizler. İstemci yalnızca en iyi çaba ile users/{uid} ve
 * üyelikleri siler; büyük veri kümeleri (çağrı/müşteri/görev) burada silinir.
 *
 * Sahip alanları koleksiyonlar arasında farklı olduğundan (agentId / userId /
 * ownerId / createdBy) her koleksiyon birden çok aday alanla sorgulanır;
 * eşleşmeyen alan boş döner, bu yüzden güvenlidir.
 */

const OWNER_FIELDS = ["agentId", "userId", "ownerId", "createdBy"];

// Kullanıcıya ait olabilecek, sahip alanıyla sorgulanabilen koleksiyonlar.
const OWNED_COLLECTIONS = [
  "office_memberships",
  "calls",
  "call_events",
  "call_summaries",
  "call_outcomes",
  "customers",
  "leads",
  "tasks",
  "notes",
  "pipeline_items",
  "notifications",
  "external_connections",
];

const DELETE_CHUNK = 400;

async function deleteByQuery(db, collection, field, uid) {
  let deleted = 0;
  // Sayfalı silme: her turda en fazla DELETE_CHUNK doküman.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await db
      .collection(collection)
      .where(field, "==", uid)
      .limit(DELETE_CHUNK)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snap.size;
    if (snap.size < DELETE_CHUNK) break;
  }
  return deleted;
}

exports.onUserAccountDeleted = functions
  .region("europe-west1")
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    if (!uid) return null;
    const db = admin.firestore();
    const summary = {};

    for (const collection of OWNED_COLLECTIONS) {
      let total = 0;
      for (const field of OWNER_FIELDS) {
        try {
          total += await deleteByQuery(db, collection, field, uid);
        } catch (e) {
          functions.logger.warn("accountDeletion purge failed", {
            uid,
            collection,
            field,
            error: String(e),
          });
        }
      }
      if (total > 0) summary[collection] = total;
    }

    // Kullanıcı kök dokümanı (istemci silemediyse).
    try {
      await db.collection("users").doc(uid).delete();
    } catch (e) {
      functions.logger.warn("accountDeletion user doc delete failed", {
        uid,
        error: String(e),
      });
    }

    functions.logger.info("accountDeletion completed", { uid, summary });
    return null;
  });
