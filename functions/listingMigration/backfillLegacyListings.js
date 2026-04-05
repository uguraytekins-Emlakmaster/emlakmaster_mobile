/**
 * Legacy `listings` dokümanlarını yeni owned-listings modeline uyumlu hale getirir.
 * Yönetici callable; dry-run ve sayfalama destekler.
 *
 * Kurallar:
 * - Mevcut dolu alanlar ezilmez (merge: true, yalnızca eksikler).
 * - Canonical senkron satırları (contentHash + platform veya rawPayloadRef): kimlik alanları doluysa dokunulmaz.
 * - Çift kayıt oluşturulmaz (yalnızca mevcut doküman güncellenir).
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldPath } = require("firebase-admin/firestore");
const { userHasManagerRole } = require("../listingImportEngine/authHelpers");

const COL_LISTINGS = "listings";
const COL_USERS = "users";

const OWNER_CANDIDATE_FIELDS = [
  "ownerUserId",
  "createdBy",
  "createdByUid",
  "agentId",
  "advisorId",
  "userId",
  "ownerUid",
];

/**
 * @param {FirebaseFirestore.DocumentData} d
 */
function inferOwnerUserIdFromLegacy(d) {
  for (const k of OWNER_CANDIDATE_FIELDS) {
    const v = d[k];
    if (typeof v === "string" && v.length > 8 && !v.includes(" ")) {
      return { uid: v, field: k };
    }
  }
  return null;
}

/**
 * @param {FirebaseFirestore.DocumentData} d
 */
function inferSourcePlatform(d) {
  const existing = String(d.sourcePlatform || "").trim();
  if (existing.length > 0) {
    return { value: existing, from: "existing" };
  }
  const src = String(d.source || "").trim().toLowerCase();
  if (src === "manual" || src === "crm" || src === "portfolio" || src.length === 0) {
    return { value: "internal", from: src.length === 0 ? "default_empty_source" : "source_field" };
  }
  return { value: "internal", from: "source_field_default" };
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 */
async function resolveOfficeIdForUser(db, uid) {
  const snap = await db.collection(COL_USERS).doc(uid).get();
  if (!snap.exists) return null;
  const oid = snap.data().officeId;
  return typeof oid === "string" && oid.length > 0 ? oid : null;
}

/**
 * Sorgu + UI için model tamam mı?
 * @param {FirebaseFirestore.DocumentData} d
 */
function isFullyCompatible(d) {
  const hasAnchor =
    (typeof d.ownerUserId === "string" && d.ownerUserId.length > 0) ||
    (typeof d.officeId === "string" && d.officeId.length > 0);
  const hasIds =
    typeof d.sourcePlatform === "string" &&
    d.sourcePlatform.length > 0 &&
    typeof d.sourceListingId === "string" &&
    d.sourceListingId.length > 0;
  const hasOwnedFlag = typeof d.isOwnedByOffice === "boolean";
  const hasSync = typeof d.syncStatus === "string" && d.syncStatus.length > 0;
  return hasAnchor && hasIds && hasOwnedFlag && hasSync;
}

/**
 * @param {string} docId
 * @param {FirebaseFirestore.DocumentData} d
 * @param {object} opts
 */
function buildMergePatch(docId, d, opts) {
  const merge = {};
  const notes = [];

  const applyFallbackOwner = opts.applyFallbackOwner === true && opts.confirmBulkFallback === true;
  const applyFallbackOffice = opts.applyFallbackOffice === true && opts.confirmBulkFallback === true;
  const fallbackOwner = opts.fallbackOwnerUserId;
  const fallbackOffice = opts.fallbackOfficeId;

  let ownerUid =
    typeof d.ownerUserId === "string" && d.ownerUserId.length > 0 ? d.ownerUserId : null;
  let ownerSrc = "existing";

  if (!ownerUid) {
    const inf = inferOwnerUserIdFromLegacy(d);
    if (inf) {
      ownerUid = inf.uid;
      ownerSrc = inf.field;
    }
  }
  if (!ownerUid && applyFallbackOwner && typeof fallbackOwner === "string" && fallbackOwner.length > 8) {
    ownerUid = fallbackOwner.trim();
    ownerSrc = "fallback_parameter";
  }

  if (!d.ownerUserId && ownerUid) {
    merge.ownerUserId = ownerUid;
    notes.push(`ownerUserId<=${ownerSrc}`);
  }

  let officeId = typeof d.officeId === "string" && d.officeId.length > 0 ? d.officeId : null;
  if (!officeId && applyFallbackOffice && typeof fallbackOffice === "string" && fallbackOffice.length > 0) {
    merge.officeId = fallbackOffice.trim();
    notes.push("officeId<=fallback_parameter");
  }

  if (!d.sourceListingId) {
    merge.sourceListingId = docId;
    notes.push("sourceListingId<=docId");
  }

  if (!d.sourcePlatform) {
    const sp = inferSourcePlatform(d);
    merge.sourcePlatform = sp.value;
    notes.push(`sourcePlatform<=${sp.from}`);
  }

  if (d.isOwnedByOffice === undefined || d.isOwnedByOffice === null) {
    merge.isOwnedByOffice = true;
    notes.push("isOwnedByOffice<=true");
  }

  if (!d.syncStatus) {
    merge.syncStatus = "synced";
    notes.push("syncStatus<=synced");
  }

  const uidForOffice =
    merge.ownerUserId || (typeof d.ownerUserId === "string" ? d.ownerUserId : null) || ownerUid;

  return {
    merge,
    /** officeId merge'te yoksa ve dokümanda yoksa users/{uid} ile doldurulabilir */
    uidForOfficeLookup:
      !merge.officeId && !officeId && typeof uidForOffice === "string" ? uidForOffice : null,
    notes,
  };
}

const REGION = "europe-west1";

exports.backfillLegacyListings = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const callerUid = context.auth.uid;
    const db = admin.firestore();
    if (!(await userHasManagerRole(db, callerUid))) {
      throw new functions.https.HttpsError("permission-denied", "Yönetici yetkisi gerekli.");
    }

    const dryRun = data.dryRun === true;
    const maxDocs = Math.min(Math.max(Number(data.maxDocs) || 400, 1), 500);
    const lastDocId = typeof data.cursor === "string" && data.cursor.length > 0 ? data.cursor : null;

    const opts = {
      applyFallbackOwner: data.applyFallbackOwner === true,
      applyFallbackOffice: data.applyFallbackOffice === true,
      confirmBulkFallback: data.confirmBulkFallback === true,
      fallbackOwnerUserId: typeof data.fallbackOwnerUserId === "string" ? data.fallbackOwnerUserId : "",
      fallbackOfficeId: typeof data.fallbackOfficeId === "string" ? data.fallbackOfficeId : "",
    };

    let q = db.collection(COL_LISTINGS).orderBy(FieldPath.documentId()).limit(maxDocs);
    if (lastDocId) {
      const lastSnap = await db.collection(COL_LISTINGS).doc(lastDocId).get();
      if (lastSnap.exists) {
        q = q.startAfter(lastSnap);
      }
    }

    const snap = await q.get();
    const summary = {
      ok: true,
      dryRun,
      scanned: snap.size,
      updated: 0,
      skippedAlreadyCompatible: 0,
      wouldUpdate: 0,
      stillMissingOwnerAndOffice: 0,
      samples: [],
      lastDocId: null,
    };

    const batch = db.batch();
    let batchOps = 0;
    const now = admin.firestore.FieldValue.serverTimestamp();

    for (const doc of snap.docs) {
      summary.lastDocId = doc.id;
      const d = doc.data();

      if (isFullyCompatible(d)) {
        summary.skippedAlreadyCompatible++;
        continue;
      }

      const { merge, uidForOfficeLookup, notes } = buildMergePatch(doc.id, d, opts);

      if (uidForOfficeLookup) {
        const oid = await resolveOfficeIdForUser(db, uidForOfficeLookup);
        if (oid) {
          merge.officeId = oid;
          notes.push("officeId<=users_doc");
        }
      }

      const afterOwner =
        merge.ownerUserId ||
        (typeof d.ownerUserId === "string" && d.ownerUserId.length > 0 ? d.ownerUserId : null);
      const afterOffice =
        merge.officeId || (typeof d.officeId === "string" && d.officeId.length > 0 ? d.officeId : null);
      if (!afterOwner && !afterOffice) {
        summary.stillMissingOwnerAndOffice++;
      }

      const hasWrites = Object.keys(merge).length > 0;
      if (!hasWrites) {
        continue;
      }

      merge.listingMigration = {
        backfillVersion: 1,
        backfilledAt: now,
        dryRun,
        notes: notes.slice(0, 24),
      };
      merge.updatedAt = now;

      if (dryRun) {
        summary.wouldUpdate++;
        if (summary.samples.length < 10) {
          summary.samples.push({ id: doc.id, mergePreview: merge, notes });
        }
        continue;
      }

      batch.set(doc.ref, merge, { merge: true });
      batchOps++;
      summary.updated++;

      if (batchOps >= 400) {
        break;
      }
    }

    if (!dryRun && batchOps > 0) {
      await batch.commit();
    }

    return summary;
  });
