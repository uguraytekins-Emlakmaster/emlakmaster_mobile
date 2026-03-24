const admin = require("firebase-admin");
const crypto = require("crypto");
const path = require("path");
const { parse: parseCsvSync } = require("csv-parse/sync");
const XLSX = require("xlsx");
const { ImportErrorCodes } = require("./errors");
const { TASK_STATUSES } = require("./constants");
const {
  buildDuplicateFingerprint,
  findDuplicateListing,
  makeDocId,
} = require("./duplicateService");
const { upsertIntegrationListing } = require("../integrationListingsAdmin");
const { patchTask, COL } = require("./listingImportProcessor");

/**
 * @param {Buffer} buf
 * @param {string} fileName
 * @returns {{ rows: object[], format: string }}
 */
function parseFileBuffer(buf, fileName) {
  const ext = path.extname(fileName || "").toLowerCase();
  if (ext === ".json") {
    const j = JSON.parse(buf.toString("utf8"));
    const rows = Array.isArray(j) ? j : j.rows || j.listings || [];
    if (!Array.isArray(rows)) throw new Error("JSON root must be array or {rows|listings}");
    return { rows, format: "json" };
  }
  if (ext === ".csv" || ext === ".txt") {
    const text = buf.toString("utf8");
    if (!text.trim()) throw new Error(ImportErrorCodes.EMPTY_FILE);
    const rows = parseCsvSync(text, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
      relax_column_count: true,
    });
    return { rows, format: "csv" };
  }
  if (ext === ".xlsx" || ext === ".xls") {
    const wb = XLSX.read(buf, { type: "buffer" });
    const sheet = wb.Sheets[wb.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: "" });
    return { rows, format: "xlsx" };
  }
  throw new Error(ImportErrorCodes.FILE_FORMAT_ERROR);
}

/**
 * mapping: { title, price, city, images, description } — CSV sütun adları
 */
function mapRow(row, mapping, platform) {
  const g = (key) => {
    const col = mapping[key];
    if (!col || typeof row !== "object") return null;
    const v = row[col];
    if (v === undefined || v === null) return null;
    return String(v).trim();
  };
  const title = g("title") || "";
  const priceRaw = g("price");
  let price = null;
  if (priceRaw) {
    const n = parseFloat(String(priceRaw).replace(/\./g, "").replace(",", "."));
    if (!Number.isNaN(n)) price = n;
  }
  const city = g("city");
  const district = g("district");
  const description = g("description");
  const imagesRaw = g("images");
  let images = [];
  if (imagesRaw) {
    images = String(imagesRaw)
      .split(/[;,\n]/)
      .map((s) => s.trim())
      .filter(Boolean)
      .slice(0, 24);
  }
  const externalListingId = g("externalListingId") || g("externalId") || null;
  const sourceUrl = g("sourceUrl") || g("link") || "";
  return {
    title,
    price,
    city,
    district,
    description,
    images,
    externalListingId,
    sourceUrl,
    platform: platform || "sahibinden",
  };
}

function fallbackExternalId(row, index) {
  const h = crypto.createHash("sha256").update(JSON.stringify(row) + index, "utf8").digest("hex");
  return `file_${h.slice(0, 28)}`;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {admin.storage.Storage} bucket
 * @param {string} taskId
 * @param {object} task
 */
async function processFileImportTask(db, bucket, taskId, task) {
  await patchTask(db, taskId, { status: TASK_STATUSES.processing });

  const ownerUserId = task.ownerUserId;
  const storagePath = task.storagePath;
  const fileName = task.fileName || "import.csv";
  const mapping = task.mapping || {};
  const officeId = String(task.officeId || "");
  const importMode = task.importMode || "skip_duplicates";
  const platform = task.platform || "sahibinden";
  const requireApproval = task.requireApproval === true;

  if (!storagePath || typeof storagePath !== "string") {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: ImportErrorCodes.MALFORMED_PAYLOAD,
      errorMessage: "storagePath eksik.",
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  let buf;
  try {
    const [file] = await bucket.file(storagePath).download();
    buf = file;
  } catch (e) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: ImportErrorCodes.STORAGE_READ_FAILED,
      errorMessage: String(e.message || e),
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  let parsed;
  try {
    parsed = parseFileBuffer(buf, fileName);
  } catch (e) {
    const code =
      String(e.message) === ImportErrorCodes.EMPTY_FILE
        ? ImportErrorCodes.EMPTY_FILE
        : ImportErrorCodes.FILE_FORMAT_ERROR;
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: code,
      errorMessage: String(e.message || e),
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const rows = parsed.rows;
  if (!rows.length) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: ImportErrorCodes.EMPTY_FILE,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const invalidRows = [];
  if (!mapping.title) {
    invalidRows.push({ reason: "mapping_title_required" });
  }

  let imported = 0;
  let duplicates = 0;
  let errors = 0;
  const integrationListingDocIds = [];
  const externalListingIds = [];
  const previews = [];
  const connectionId = `import_file_${taskId}`.slice(0, 120);

  if (!mapping.title) {
    await patchTask(db, taskId, {
      status: TASK_STATUSES.failed,
      errorCode: ImportErrorCodes.MALFORMED_PAYLOAD,
      errorMessage: "title mapping zorunlu.",
      invalidRowsPreview: invalidRows,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  // async for loop
  for (let index = 0; index < rows.length; index++) {
    const row = rows[index];
    try {
      const m = mapRow(row, mapping, platform);
      if (!m.title || m.title.length < 2) {
        invalidRows.push({ index, reason: "missing_title" });
        errors++;
        continue;
      }
      const extId =
        m.externalListingId && m.externalListingId.length > 1 ? m.externalListingId : fallbackExternalId(row, index);
      const fingerprint = buildDuplicateFingerprint(m.title, m.price, m.city, m.district);
      const dup = await findDuplicateListing(db, ownerUserId, m.platform, extId, fingerprint);

      if (dup && importMode === "skip_duplicates") {
        duplicates++;
        continue;
      }
      if (dup && importMode === "create_new") {
        duplicates++;
        continue;
      }

      let docId = makeDocId(connectionId, m.platform, extId);
      if (dup && importMode === "update_duplicates") {
        docId = dup.doc.id;
      }

      const listingPayload = {
        connectionId,
        platform: m.platform,
        externalListingId: extId,
        title: m.title,
        description: m.description,
        price: m.price,
        currency: "TRY",
        city: m.city,
        district: m.district,
        images: m.images,
        sourceUrl: m.sourceUrl || "",
        officeId,
        duplicateFingerprint: fingerprint,
        syncHash: crypto.createHash("sha256").update(JSON.stringify(row), "utf8").digest("hex"),
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

  if (requireApproval && previews.length > 0) {
    await db.collection(COL).doc(taskId).set(
      {
        status: TASK_STATUSES.pending_approval,
        previewPayload: { batch: previews, invalidRows, format: parsed.format },
        counts: { imported: 0, duplicates, errors: errors + invalidRows.length },
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return;
  }

  await db.collection(COL).doc(taskId).set(
    {
      status: imported === 0 && errors > 0 ? TASK_STATUSES.failed : TASK_STATUSES.completed,
      errorCode: imported === 0 && errors > 0 ? ImportErrorCodes.PARSE_FAILED : null,
      integrationListingDocIds,
      externalListingIds,
      invalidRowsPreview: invalidRows.slice(0, 50),
      format: parsed.format,
      counts: { imported, duplicates, errors },
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

module.exports = {
  parseFileBuffer,
  mapRow,
  processFileImportTask,
};
