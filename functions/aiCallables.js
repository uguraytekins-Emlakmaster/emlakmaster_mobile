/**
 * Callable: enrichPostCallSummary, generateBulkCampaignMessage
 * — aiRemoteGuard ile sarılı; gerçek LLM burada veya alt modülde takılabilir.
 */
const functions = require("firebase-functions");
const { guardRemoteAi } = require("./aiRemoteGuard");

/**
 * Sunucu tarafı placeholder: API anahtarı yokken bile anlamlı kısa metin (istemci boş dönerse yine heuristic kullanır).
 */
function placeholderPostCallEnrichment(data) {
  const summary = String(data.summary || "").trim();
  const transcript = String(data.transcript || "").trim();
  const base = summary.length > 0 ? summary : transcript;
  const short =
    base.length > 0
      ? base.slice(0, 220) + (base.length > 220 ? "…" : "")
      : "Görüşme özeti için yeterli metin alınamadı.";
  return {
    aiSummaryShortTr: short,
    aiCustomerMoodTr: "Nötr",
    aiObjectionTypeTr: "Belirtilmedi",
    aiFollowUpStyleTr: "Standart takip",
    aiBrokerNoteTr: "Sunucu placeholder — üretimde LLM ile değiştirilebilir.",
  };
}

function placeholderBulkCampaign(data) {
  const stats = data.stats || {};
  const n = stats.totalCustomers || 0;
  const phones = stats.phoneCount || 0;
  const msg =
    `Merhaba, portföyümüzde size uygun yeni ilanlar güncellendi (yaklaşık ${n} kayıt, ${phones} numara). ` +
    `Uygun olduğunuzda kısa bir telefonla üzerinden birlikte geçebiliriz.`;
  return { message: msg, text: msg };
}

function buildIdempotentPayloadPostCall(data) {
  return {
    enrichmentInputMode: data.enrichmentInputMode || "",
    summary: String(data.summary || "").slice(0, 12000),
    transcript: String(data.transcript || "").slice(0, 12000),
    heuristicVersion: data.heuristicVersion ?? null,
  };
}

function buildIdempotentPayloadCampaign(data) {
  return {
    currentMessage: String(data.currentMessage || "").slice(0, 8000),
    stats: data.stats || {},
    sampleCustomers: data.sampleCustomers || [],
  };
}

exports.enrichPostCallSummary = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onCall(async (data, context) => {
    const payload = buildIdempotentPayloadPostCall(data || {});
    return guardRemoteAi(context, "enrichPostCallSummary", payload, async () =>
      placeholderPostCallEnrichment(data || {})
    );
  });

exports.generateBulkCampaignMessage = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onCall(async (data, context) => {
    const payload = buildIdempotentPayloadCampaign(data || {});
    return guardRemoteAi(context, "generateBulkCampaignMessage", payload, async () =>
      placeholderBulkCampaign(data || {})
    );
  });
