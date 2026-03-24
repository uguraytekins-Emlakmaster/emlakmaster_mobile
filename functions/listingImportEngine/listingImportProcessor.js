const admin = require("firebase-admin");
const crypto = require("crypto");
const { ImportErrorCodes } = require("./errors");
const { TASK_STATUSES, SOURCE_TYPES } = require("./constants");
const { detectPlatformFromUrl } = require("./urlPlatform");
const { fetchListingHtml } = require("./fetchHtml");
const { parseListingHtml } = require("./parsers");
const {
  buildDuplicateFingerprint,
  findDuplicateListing,
  makeDocId,
} = require("./duplicateService");
const { upsertIntegrationListing } = require("../integrationListingsAdmin");

const COL = "listing_import_tasks";

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} taskId
 * @param {object} patch
 */
async function patchTask(db, taskId, patch) {
  await db.collection(COL).doc(taskId).set(
    {
      ...patch,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/**
 * @param {string} sourceUrl
 */
function fallbackExternalIdFromUrl(sourceUrl) {
  return `url_${crypto.createHash("sha256").update(sourceUrl, "utf8").digest("hex").slice(0, 32)}`;
}

/**
 * URL görevi — HTML çek, parse et, duplicate kuralları, upsert.
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} taskId
 * @param {object} task
 */
async function processUrlImportTask(db, taskId, task) {
  const ownerUserId = task.ownerUserId;
  const sourceUrl = task.sourceUrl;
  const officeId = String(task.officeId || "");
  const importMode = task.importMode || "skip_duplicates";
  const requireApproval = task.requireApproval === true;

  await patchTask(db, taskId, { status: TASK_STATUSES.processing });

  const det = detectPlatformFromUrl(sourceUrl);
  if (!det.ok) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: det.errorCode || ImportErrorCodes.INVALID_URL,
      errorMessage: "Geçersiz veya desteklenmeyen URL.",
      counts: { imported: 0, duplicates: 0, errors: 1 },
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const platform = det.platform;
  const fetched = await fetchListingHtml(sourceUrl);
  if (!fetched.ok || !fetched.html) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: ImportErrorCodes.PARSE_FAILED,
      errorMessage: fetched.error || "Sayfa alınamadı.",
      counts: { imported: 0, duplicates: 0, errors: 1 },
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  let parsed;
  try {
    parsed = parseListingHtml(platform, fetched.html, sourceUrl);
  } catch (e) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: ImportErrorCodes.PARSE_FAILED,
      errorMessage: String(e.message || e),
      counts: { imported: 0, duplicates: 0, errors: 1 },
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const externalListingId =
    parsed.externalListingId && String(parsed.externalListingId).length > 2
      ? String(parsed.externalListingId)
      : fallbackExternalIdFromUrl(sourceUrl);

  const fingerprint = buildDuplicateFingerprint(
    parsed.title,
    parsed.price,
    parsed.city,
    parsed.district
  );

  const dup = await findDuplicateListing(db, ownerUserId, platform, externalListingId, fingerprint);

  if (dup && importMode === "skip_duplicates") {
    await patchTask(db, taskId, {
      status: parsed.partial ? TASK_STATUSES.partial : TASK_STATUSES.completed,
      errorCode: parsed.partial ? ImportErrorCodes.IMPORT_PARTIAL : null,
      duplicateOfListingId: dup.doc.id,
      duplicateReason: dup.reason,
      counts: { imported: 0, duplicates: 1, errors: 0 },
      platform,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  if (dup && importMode === "create_new") {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.completed,
      duplicateOfListingId: dup.doc.id,
      duplicateReason: dup.reason,
      counts: { imported: 0, duplicates: 1, errors: 0 },
      platform,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const connectionId = "import_url";
  /** @type {string} */
  let docId = makeDocId(connectionId, platform, externalListingId);
  if (dup && importMode === "update_duplicates") {
    docId = dup.doc.id;
  }

  const listingPayload = {
    connectionId,
    platform,
    externalListingId,
    title: parsed.title,
    description: parsed.description,
    price: parsed.price,
    currency: parsed.currency || "TRY",
    category: parsed.category,
    city: parsed.city,
    district: parsed.district,
    images: parsed.images || [],
    sourceUrl,
    officeId,
    duplicateFingerprint: fingerprint,
    syncHash: crypto.createHash("sha256").update(`${sourceUrl}|${fetched.status}`, "utf8").digest("hex"),
  };

  if (requireApproval) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.pending_approval,
      platform,
      previewPayload: { docId, listingPayload },
      partial: !!parsed.partial,
      errorCode: parsed.partial ? ImportErrorCodes.IMPORT_PARTIAL : null,
      counts: { imported: 0, duplicates: 0, errors: 0 },
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  await upsertIntegrationListing(db, docId, ownerUserId, listingPayload);

  await patchTask(db, taskId, {
    status: parsed.partial ? TASK_STATUSES.partial : TASK_STATUSES.completed,
    errorCode: parsed.partial ? ImportErrorCodes.IMPORT_PARTIAL : null,
    integrationListingDocIds: [docId],
    externalListingIds: [externalListingId],
    platform,
    counts: { imported: 1, duplicates: 0, errors: 0 },
    partial: !!parsed.partial,
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Uzantıdan gelen toplu ilanlar (parse edilmiş JSON).
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} ownerUserId
 * @param {object} opts
 */
async function processExtensionListings(db, ownerUserId, opts) {
  const {
    platform,
    listings,
    officeId = "",
    importMode = "skip_duplicates",
    requireApproval = false,
    taskId = null,
  } = opts;

  let imported = 0;
  let duplicates = 0;
  let errors = 0;
  const integrationListingDocIds = [];
  const externalListingIds = [];
  const previews = [];

  const connectionId = "import_extension";

  for (const raw of listings) {
    try {
      const externalListingId = String(raw.externalListingId || raw.externalId || "").trim() || null;
      const title = String(raw.title || "").trim();
      const sourceUrl = String(raw.sourceUrl || raw.link || "").trim();
      if (!title && !sourceUrl) {
        errors++;
        continue;
      }
      const extId = externalListingId || (sourceUrl ? fallbackExternalIdFromUrl(sourceUrl) : `gen_${crypto.randomBytes(8).toString("hex")}`);
      const price =
        typeof raw.price === "number"
          ? raw.price
          : parseFloat(String(raw.price || "").replace(/\./g, "").replace(",", ".")) || null;
      const city = raw.city ? String(raw.city) : null;
      const district = raw.district ? String(raw.district) : null;
      const fingerprint = buildDuplicateFingerprint(title, price, city, district);
      const dup = await findDuplicateListing(db, ownerUserId, platform, extId, fingerprint);

      if (dup && importMode === "skip_duplicates") {
        duplicates++;
        continue;
      }
      if (dup && importMode === "create_new") {
        duplicates++;
        continue;
      }

      let docId = makeDocId(connectionId, platform, extId);
      if (dup && importMode === "update_duplicates") {
        docId = dup.doc.id;
      }
      const listingPayload = {
        connectionId,
        platform,
        externalListingId: extId,
        title,
        description: raw.description ? String(raw.description) : null,
        price,
        currency: raw.currency || "TRY",
        category: raw.category ? String(raw.category) : null,
        city,
        district,
        images: Array.isArray(raw.images) ? raw.images.map((x) => String(x)) : [],
        sourceUrl: sourceUrl || "",
        officeId: String(officeId || ""),
        duplicateFingerprint: fingerprint,
        syncHash: crypto.createHash("sha256").update(JSON.stringify(raw), "utf8").digest("hex"),
      };

      if (requireApproval) {
        previews.push({ docId, listingPayload });
        continue;
      }

      await upsertIntegrationListing(db, docId, ownerUserId, listingPayload);
      imported++;
      integrationListingDocIds.push(docId);
      externalListingIds.push(extId);
    } catch {
      errors++;
    }
  }

  if (taskId) {
    if (requireApproval && previews.length > 0) {
      await patchTask(db, taskId, {
        status: TASK_STATUSES.pending_approval,
        previewPayload: { batch: previews },
        counts: { imported: 0, duplicates, errors },
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      await patchTask(db, taskId, {
        status: errors > 0 && imported === 0 ? TASK_STATUSES.failed : TASK_STATUSES.completed,
        errorCode: errors > 0 && imported === 0 ? ImportErrorCodes.EXTENSION_ERROR : null,
        integrationListingDocIds,
        externalListingIds,
        platform,
        counts: { imported, duplicates, errors },
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  return { imported, duplicates, errors, integrationListingDocIds, externalListingIds };
}

/**
 * Onay sonrası `integration_listings` yazımı (previewPayload şeması).
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} ownerUserId
 * @param {object} previewPayload
 */
async function applyApprovedPreviewPayload(db, ownerUserId, previewPayload) {
  const p = previewPayload;
  if (!p) return { written: 0 };
  if (p.batch && Array.isArray(p.batch)) {
    let n = 0;
    for (const item of p.batch) {
      if (item.docId && item.listingPayload) {
        await upsertIntegrationListing(db, item.docId, ownerUserId, item.listingPayload);
        n++;
      }
    }
    return { written: n };
  }
  if (p.docId && p.listingPayload) {
    await upsertIntegrationListing(db, p.docId, ownerUserId, p.listingPayload);
    return { written: 1 };
  }
  return { written: 0 };
}

module.exports = {
  processUrlImportTask,
  processExtensionListings,
  applyApprovedPreviewPayload,
  patchTask,
  COL,
  TASK_STATUSES,
  SOURCE_TYPES,
};
