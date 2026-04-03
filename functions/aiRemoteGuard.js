/**
 * Sunucu tarafı AI maliyet koruması: kill switch, kota, idempotency, yapılandırılmış log.
 * İstemci [AiGate] ile birlikte çalışır; reddedilen istekler HttpsError ile döner (istemci heuristic’e düşer).
 */
const crypto = require("crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

const COL_SETTINGS = "app_settings";
const DOC_AI_CONTROL = "ai_remote_control";
const COL_IDEMP = "ai_idempotency_cache";
const COL_USERS = "users";
const SUB_QUOTA = "_ai_remote_quota";
const DOC_DAILY = "daily";

const IDEMP_TTL_MS = 48 * 60 * 60 * 1000;

function utcDayString() {
  return new Date().toISOString().slice(0, 10);
}

function stableStringify(obj) {
  if (obj === null || typeof obj !== "object") return JSON.stringify(obj);
  if (Array.isArray(obj)) return `[${obj.map(stableStringify).join(",")}]`;
  const keys = Object.keys(obj).sort();
  return `{${keys.map((k) => JSON.stringify(k) + ":" + stableStringify(obj[k])).join(",")}}`;
}

/**
 * İstek gövdesinden idempotency anahtarı (aynı içerik → aynı hash).
 */
function idempotencyKey(functionName, payload) {
  const canonical = stableStringify({ functionName, payload });
  return crypto.createHash("sha256").update(canonical).digest("hex");
}

async function readKillSwitch(db) {
  const snap = await db.collection(COL_SETTINGS).doc(DOC_AI_CONTROL).get();
  if (!snap.exists) return { remoteAiDisabled: false };
  const d = snap.data() || {};
  return {
    remoteAiDisabled: Boolean(d.remoteAiDisabled === true || d.killSwitch === true),
    maxPostCallPerDay: typeof d.maxPostCallPerDay === "number" ? d.maxPostCallPerDay : null,
    maxCampaignPerDay: typeof d.maxCampaignPerDay === "number" ? d.maxCampaignPerDay : null,
  };
}

async function getCachedResponse(db, key) {
  const ref = db.collection(COL_IDEMP).doc(key);
  const snap = await ref.get();
  if (!snap.exists) return null;
  const data = snap.data() || {};
  const createdMs = data.createdAt?.toMillis?.() || 0;
  if (Date.now() - createdMs > IDEMP_TTL_MS) return null;
  if (data.response == null) return null;
  return data.response;
}

async function setCachedResponse(db, key, uid, functionName, response) {
  await db.collection(COL_IDEMP).doc(key).set({
    response,
    uid,
    functionName,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function getEnvLimit(envName, fallback) {
  const v = parseInt(process.env[envName] || String(fallback), 10);
  return Number.isFinite(v) && v > 0 ? v : fallback;
}

/**
 * Günlük kota — kullanıcı başına [SUB_QUOTA]/[DOC_DAILY].
 */
async function consumeDailyQuota(db, uid, fieldName, dailyLimit) {
  const day = utcDayString();
  const ref = db.collection(COL_USERS).doc(uid).collection(SUB_QUOTA).doc(DOC_DAILY);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    let enrichPostCallCount = 0;
    let bulkCampaignCount = 0;
    let storedDay = day;
    if (snap.exists) {
      const d = snap.data() || {};
      storedDay = d.day || day;
      enrichPostCallCount = d.enrichPostCallCount || 0;
      bulkCampaignCount = d.bulkCampaignCount || 0;
    }
    if (storedDay !== day) {
      enrichPostCallCount = 0;
      bulkCampaignCount = 0;
    }
    const cur = fieldName === "enrichPostCallCount" ? enrichPostCallCount : bulkCampaignCount;
    if (cur >= dailyLimit) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "daily_ai_quota_exceeded",
        { dailyLimit, fieldName, day }
      );
    }
    const next = {
      day,
      enrichPostCallCount,
      bulkCampaignCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (fieldName === "enrichPostCallCount") next.enrichPostCallCount = enrichPostCallCount + 1;
    else next.bulkCampaignCount = bulkCampaignCount + 1;
    tx.set(ref, next, { merge: true });
  });
}

function logAiEvent(event, fields) {
  functions.logger.info(
    JSON.stringify({
      severity: "INFO",
      aiRemote: true,
      event,
      ...fields,
    })
  );
}

/**
 * @param {object} context - callable context
 * @param {string} functionName - 'enrichPostCallSummary' | 'generateBulkCampaignMessage'
 * @param {object} payload - idempotency için kanonik veri (data)
 * @param {() => Promise<object>} executor - koruma geçildikten sonra çalışacak üretici (placeholder veya gerçek LLM)
 */
async function guardRemoteAi(context, functionName, payload, executor) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Oturum gerekli.");
  }
  const uid = context.auth.uid;
  const db = admin.firestore();

  const ks = await readKillSwitch(db);
  if (ks.remoteAiDisabled) {
    logAiEvent("remote_ai_disabled", { functionName, uid });
    throw new functions.https.HttpsError("failed-precondition", "remote_ai_disabled");
  }

  const idemKey = idempotencyKey(functionName, payload);
  const cached = await getCachedResponse(db, idemKey);
  if (cached) {
    logAiEvent("idempotent_cache_hit", {
      functionName,
      uid,
      keyPrefix: idemKey.slice(0, 16),
    });
    return { ...cached, _meta: { cached: true, idempotencyKey: idemKey.slice(0, 16) } };
  }

  const postLimit =
    ks.maxPostCallPerDay != null
      ? ks.maxPostCallPerDay
      : getEnvLimit("AI_POSTCALL_DAILY_LIMIT", 30);
  const campLimit =
    ks.maxCampaignPerDay != null
      ? ks.maxCampaignPerDay
      : getEnvLimit("AI_CAMPAIGN_DAILY_LIMIT", 20);

  const fieldName =
    functionName === "enrichPostCallSummary" ? "enrichPostCallCount" : "bulkCampaignCount";
  const dailyLimit = functionName === "enrichPostCallSummary" ? postLimit : campLimit;

  try {
    await consumeDailyQuota(db, uid, fieldName, dailyLimit);
  } catch (e) {
    if (e instanceof functions.https.HttpsError) {
      logAiEvent("quota_blocked", {
        functionName,
        uid,
        code: e.code,
        keyPrefix: idemKey.slice(0, 16),
      });
    }
    throw e;
  }

  let result;
  try {
    result = await executor();
  } catch (err) {
    logAiEvent("executor_error", {
      functionName,
      uid,
      message: String(err && err.message ? err.message : err),
    });
    throw err;
  }

  await setCachedResponse(db, idemKey, uid, functionName, result);
  logAiEvent("remote_ai_ok", {
    functionName,
    uid,
    keyPrefix: idemKey.slice(0, 16),
    dailyLimit,
  });
  return { ...result, _meta: { cached: false, idempotencyKey: idemKey.slice(0, 16) } };
}

module.exports = {
  guardRemoteAi,
  idempotencyKey,
  stableStringify,
};
