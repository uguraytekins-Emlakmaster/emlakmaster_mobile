/**
 * Cloud Functions köprüsü — index.js bu modülü export eder.
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { COL_LISTING_IMPORT_TASKS, TASK_STATUSES, SOURCE_TYPES } = require("./constants");
const { ImportErrorCodes } = require("./errors");
const {
  processUrlImportTask,
  processExtensionListings,
  applyApprovedPreviewPayload,
  patchTask,
} = require("./listingImportProcessor");
const { processFileImportTask } = require("./fileImportProcessor");
const { detectPlatformFromUrl } = require("./urlPlatform");
const { userHasManagerRole, verifyBearerAndGetUid } = require("./authHelpers");
const { runManualListingSync } = require("./syncEngine");

const REGION = "europe-west1";

function db() {
  return admin.firestore();
}

/**
 * Callable: URL ile import kuyruğu — UI bloklanmaz; işlem Firestore trigger ile.
 */
exports.enqueueUrlImport = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 30, memory: "256MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const uid = context.auth.uid;
    const url = typeof data.url === "string" ? data.url.trim() : "";
    const officeId = typeof data.officeId === "string" ? data.officeId : "";
    const importMode = data.importMode || "skip_duplicates";
    const requireApproval = data.requireApproval === true;

    const det = detectPlatformFromUrl(url);
    if (!det.ok) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        det.errorCode || ImportErrorCodes.INVALID_URL,
        { code: det.errorCode || ImportErrorCodes.INVALID_URL }
      );
    }

    const ref = db().collection(COL_LISTING_IMPORT_TASKS).doc();
    await ref.set({
      ownerUserId: uid,
      officeId,
      sourceType: SOURCE_TYPES.url,
      status: TASK_STATUSES.queued,
      platform: det.platform,
      sourceUrl: url,
      importMode,
      requireApproval,
      counts: { imported: 0, duplicates: 0, errors: 0 },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true, taskId: ref.id, platform: det.platform };
  });

/**
 * Callable: Storage'a yüklenen dosyayı işle (görev oluşturur; trigger işler).
 */
exports.enqueueFileImport = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 60, memory: "512MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const uid = context.auth.uid;
    const storagePath = typeof data.storagePath === "string" ? data.storagePath.trim() : "";
    const fileName = typeof data.fileName === "string" ? data.fileName : "import.csv";
    const mapping = data.mapping && typeof data.mapping === "object" ? data.mapping : {};
    const officeId = typeof data.officeId === "string" ? data.officeId : "";
    const importMode = data.importMode || "skip_duplicates";
    const platform = typeof data.platform === "string" ? data.platform : "sahibinden";
    const requireApproval = data.requireApproval === true;

    if (!storagePath || !storagePath.startsWith(`users/${uid}/imports/`)) {
      throw new functions.https.HttpsError("invalid-argument", "Geçersiz storage yolu.");
    }

    const ref = db().collection(COL_LISTING_IMPORT_TASKS).doc();
    await ref.set({
      ownerUserId: uid,
      officeId,
      sourceType: SOURCE_TYPES.file,
      status: TASK_STATUSES.queued,
      platform,
      storagePath,
      fileName,
      mapping,
      importMode,
      requireApproval,
      counts: { imported: 0, duplicates: 0, errors: 0 },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true, taskId: ref.id };
  });

/**
 * Firestore: yeni import görevi → arka planda işle.
 */
exports.onListingImportTaskCreated = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .firestore.document(`${COL_LISTING_IMPORT_TASKS}/{taskId}`)
  .onCreate(async (snap, ctx) => {
    const taskId = ctx.params.taskId;
    const task = snap.data();
    if (!task || task.status !== TASK_STATUSES.queued) return;

    try {
      if (task.sourceType === SOURCE_TYPES.url) {
        await processUrlImportTask(db(), taskId, task);
      } else if (task.sourceType === SOURCE_TYPES.file) {
        const bucket = admin.storage().bucket();
        await processFileImportTask(db(), bucket, taskId, task);
      } else if (task.sourceType === SOURCE_TYPES.extension) {
        const listings = Array.isArray(task.extensionListingsPayload)
          ? task.extensionListingsPayload
          : [];
        await processExtensionListings(db(), task.ownerUserId, {
          platform: task.platform,
          listings,
          officeId: task.officeId,
          importMode: task.importMode || "skip_duplicates",
          requireApproval: task.requireApproval === true,
          taskId,
        });
      }
    } catch (e) {
      functions.logger.error("onListingImportTaskCreated", taskId, e);
      await patchTask(db(), taskId, {
        status: TASK_STATUSES.failed,
        errorCode: ImportErrorCodes.PARSE_FAILED,
        errorMessage: String(e.message || e),
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * HTTPS: Chrome uzantısı — Authorization: Bearer &lt;Firebase ID token&gt;
 * Body: { listings: [], platform, userId?, sessionToken? } — userId token.uid ile eşleşmeli.
 */
exports.extensionImport = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 120, memory: "512MB" })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: ImportErrorCodes.MALFORMED_PAYLOAD });
      return;
    }

    const authHeader = req.get("Authorization") || "";
    const m = authHeader.match(/^Bearer\s+(.+)$/i);
    const token = m ? m[1] : null;
    const uid = await verifyBearerAndGetUid(token);
    if (!uid) {
      res.status(401).json({ ok: false, error: ImportErrorCodes.PERMISSION_DENIED });
      return;
    }

    const body = req.body || {};
    const platform = typeof body.platform === "string" ? body.platform.trim() : "";
    const listings = Array.isArray(body.listings) ? body.listings : null;
    const bodyUserId = typeof body.userId === "string" ? body.userId : null;

    if (!listings || !["sahibinden", "hepsiemlak", "emlakjet"].includes(platform)) {
      res.status(400).json({ ok: false, error: ImportErrorCodes.MALFORMED_PAYLOAD });
      return;
    }
    if (bodyUserId && bodyUserId !== uid) {
      res.status(403).json({ ok: false, error: ImportErrorCodes.PERMISSION_DENIED });
      return;
    }

    const officeId = typeof body.officeId === "string" ? body.officeId : "";
    const importMode = body.importMode || "skip_duplicates";
    const requireApproval = body.requireApproval === true;

    const ref = db().collection(COL_LISTING_IMPORT_TASKS).doc();
    await ref.set({
      ownerUserId: uid,
      officeId,
      sourceType: SOURCE_TYPES.extension,
      status: TASK_STATUSES.queued,
      platform,
      extensionListingsPayload: listings,
      importMode,
      requireApproval,
      extensionMeta: {
        sessionTokenPresent: typeof body.sessionToken === "string" && body.sessionToken.length > 0,
        userAgent: req.get("User-Agent") || null,
      },
      counts: { imported: 0, duplicates: 0, errors: 0 },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ ok: true, taskId: ref.id });
  });

/**
 * Callable: yönetici — bekleyen import onayı.
 */
exports.adminApproveImportTask = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const uid = context.auth.uid;
    const okManager = await userHasManagerRole(db(), uid);
    if (!okManager) {
      throw new functions.https.HttpsError("permission-denied", ImportErrorCodes.PERMISSION_DENIED);
    }

    const taskId = typeof data.taskId === "string" ? data.taskId : "";
    const decision = data.decision === "reject" ? "reject" : "approve";
    if (!taskId) {
      throw new functions.https.HttpsError("invalid-argument", "taskId gerekli.");
    }

    const ref = db().collection(COL_LISTING_IMPORT_TASKS).doc(taskId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Görev yok.");
    }
    const task = snap.data();
    if (task.status !== TASK_STATUSES.pending_approval) {
      throw new functions.https.HttpsError("failed-precondition", "Görev onay beklemiyor.");
    }

    if (decision === "reject") {
      await ref.set(
        {
          status: TASK_STATUSES.failed,
          errorCode: "REJECTED_BY_ADMIN",
          adminNote: typeof data.note === "string" ? data.note : null,
          reviewedBy: uid,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return { ok: true, decision: "reject" };
    }

    const { written } = await applyApprovedPreviewPayload(db(), task.ownerUserId, task.previewPayload);
    await ref.set(
      {
        status: written > 0 ? TASK_STATUSES.completed : TASK_STATUSES.failed,
        reviewedBy: uid,
        counts: { imported: written, duplicates: 0, errors: written > 0 ? 0 : 1 },
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return { ok: true, decision: "approve", written };
  });

/**
 * Callable: manuel senkron (tek ilan dokümanı).
 */
exports.runIntegrationListingSync = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
    }
    const uid = context.auth.uid;
    const listingDocId = typeof data.listingDocId === "string" ? data.listingDocId : "";
    const remoteSnapshot = data.remoteSnapshot && typeof data.remoteSnapshot === "object" ? data.remoteSnapshot : {};
    if (!listingDocId) {
      throw new functions.https.HttpsError("invalid-argument", "listingDocId gerekli.");
    }
    const r = await runManualListingSync(db(), {
      ownerUserId: uid,
      listingDocId,
      remoteSnapshot,
    });
    return { ok: r.state === "success", ...r };
  });
