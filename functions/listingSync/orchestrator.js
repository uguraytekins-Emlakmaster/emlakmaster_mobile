const { runConnector } = require("./connectors/registry");
const { upsertCanonicalOwnedListing } = require("./canonicalListing");
const {
  COL_LISTING_SOURCES,
  COL_EXTERNAL_CONNECTIONS,
} = require("./constants");
const { beginSyncRun, finishSyncRun, recordSyncError } = require("./syncRun");

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {object} p
 * @param {string} p.officeId
 * @param {string} p.triggeredByUid
 */
async function runOfficeSync(db, p) {
  const { officeId, triggeredByUid } = p;
  const snap = await db.collection(COL_LISTING_SOURCES).where("officeId", "==", officeId).get();

  const activeDocs = snap.docs.filter((d) => {
    const st = d.data().status;
    return st === undefined || st === null || st === "active";
  });

  if (activeDocs.length === 0) {
    return {
      ok: true,
      runs: [],
      message: "no_active_listing_sources",
    };
  }

  const runs = [];

  for (const doc of activeDocs) {
    const src = doc.data();
    const platform = String(src.platform || "").trim();
    const connectionId = String(src.connectionId || "").trim();
    const connectorType = String(src.connectorType || "official_api").trim();

    let ownerUserId = String(src.defaultOwnerUserId || "").trim();
    if (!ownerUserId && connectionId) {
      const c = await db.collection(COL_EXTERNAL_CONNECTIONS).doc(connectionId).get();
      if (c.exists) {
        const u = c.data().userId;
        if (typeof u === "string" && u.length > 0) ownerUserId = u;
      }
    }
    if (!ownerUserId) {
      ownerUserId = triggeredByUid;
    }

    const runId = await beginSyncRun(db, {
      officeId,
      platform,
      connectorType,
      listingSourceId: doc.id,
      triggeredByUid,
    });

    /** @type {{ fetched: number, upserted: number, skippedUnchanged: number, errors: number }} */
    const stats = {
      fetched: 0,
      upserted: 0,
      skippedUnchanged: 0,
      errors: 0,
    };

    try {
      const result = await runConnector(platform, {
        db,
        officeId,
        connectionId,
        ownerUserId,
      });

      if (result.mode === "unsupported") {
        await recordSyncError(db, {
          runId,
          officeId,
          platform,
          code: "UNSUPPORTED_PLATFORM",
          message: result.message || "connector_yok",
          listingSourceId: doc.id,
        });
        await finishSyncRun(db, runId, {
          status: "failed",
          stats,
          message: result.message || "unsupported_platform",
        });
        runs.push({
          runId,
          platform,
          mode: result.mode,
          message: result.message,
        });
        continue;
      }

      const items = Array.isArray(result.items) ? result.items : [];
      stats.fetched = items.length;

      for (const it of items) {
        const sid = String(it.sourceListingId || "").trim();
        if (!sid) {
          stats.errors++;
          continue;
        }
        try {
          const loc =
            it.location ||
            [it.city, it.district].filter(Boolean).join(" · ") ||
            "";
          const r = await upsertCanonicalOwnedListing(db, {
            ownerUserId,
            officeId,
            sourcePlatform: platform,
            sourceListingId: sid,
            title: it.title,
            price: it.price,
            location: loc || null,
            imageUrl: it.imageUrl || null,
            syncHash: it.contentHash || undefined,
            rawPayloadRef: it.rawPayloadRef || null,
            syncStatus: "synced",
          });
          if (r.unchanged) stats.skippedUnchanged++;
          else stats.upserted++;
        } catch (e) {
          stats.errors++;
          await recordSyncError(db, {
            runId,
            officeId,
            platform,
            code: "UPSERT_FAILED",
            message: String(e.message || e),
            listingSourceId: doc.id,
          });
        }
      }

      const runStatus =
        stats.errors > 0 && stats.upserted + stats.skippedUnchanged === 0 ? "failed" : stats.errors > 0 ? "partial" : "success";

      await finishSyncRun(db, runId, {
        status: runStatus,
        stats,
        message: result.message || (result.mode === "not_configured" ? result.message : null),
      });

      runs.push({
        runId,
        platform,
        mode: result.mode,
        message: result.message,
      });
    } catch (e) {
      stats.errors++;
      await recordSyncError(db, {
        runId,
        officeId,
        platform,
        code: "RUN_FAILED",
        message: String(e.message || e),
        listingSourceId: doc.id,
      });
      await finishSyncRun(db, runId, {
        status: "failed",
        stats,
        message: String(e.message || e),
      });
      runs.push({ runId, platform, error: String(e.message || e) });
    }
  }

  return { ok: true, runs };
}

module.exports = {
  runOfficeSync,
};
