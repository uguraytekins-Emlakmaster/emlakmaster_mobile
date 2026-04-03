import 'package:cloud_functions/cloud_functions.dart';
import 'package:emlakmaster_mobile/core/ai/ai_gate.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment_input.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';

/// v1 önerilen yol: **Cloud Function** (API anahtarı sunucuda) → istemci yalnızca özet gönderir.
/// İstemci doğrudan LLM çağırmaz; anahtar sızması ve kota riski düşük.
///
/// Function yoksa veya hata: sezgisel **v3** [computeHeuristicPostCallAiEnrichment] ile kesintisiz devam.
///
/// Girdi: [PostCallAiEnrichmentInput] — modlar: özet yalnız, özet+transkript, transkript yalnız.
class PostCallAiEnrichmentService {
  PostCallAiEnrichmentService._();
  static final PostCallAiEnrichmentService instance = PostCallAiEnrichmentService._();

  static const Duration _timeout = Duration(seconds: 14);

  /// Beklenen callable adı: `enrichPostCallSummary`
  /// Girdi örneği: `{ "enrichmentInputMode", "summary", "transcript?", "enrichmentContext", ... }`
  /// `lastCallSummary` / kural sinyalleri burada yazılmaz; yalnızca `lastCallAiEnrichment`.
  Future<PostCallAiEnrichment> enrich({
    required PostCallAiEnrichmentInput input,
    String? sentimentStorage,
    CustomerHeatLevel? heatLevel,
    bool allowRemoteModel = true,
  }) async {
    final signalsLayer = input.signalsForAiHeuristicLayer();
    final heuristic = computeHeuristicPostCallAiEnrichment(
      input: input,
      signals: signalsLayer,
      sentimentLabelTr: sentimentStorage != null
          ? sentimentLabelTrFromStorage(sentimentStorage)
          : null,
      heatLevel: heatLevel,
    );

    if (!allowRemoteModel) {
      return heuristic;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('enrichPostCallSummary');
      final payload = <String, dynamic>{
        'enrichmentInputMode': input.mode.storageId,
        'summary': input.summaryForCrm.trim(),
        if (input.transcriptRaw != null && input.transcriptRaw!.trim().isNotEmpty)
          'transcript': input.transcriptRaw!.trim(),
        'enrichmentContext': input.enrichmentContextText,
        if (signalsLayer != null) 'signals': signalsLayer.toFirestorePayload(),
        if (sentimentStorage != null) 'sentiment': sentimentStorage,
        if (heatLevel != null) 'heatLevel': heatLevel.name,
        if (input.transcriptRaw != null && input.transcriptRaw!.trim().isNotEmpty)
          'transcriptQuality': transcriptQualityLabelForPayload(input.transcriptRaw),
        'heuristicVersion': 3,
      };
      final res = await callable.call(payload).timeout(_timeout);
      final raw = res.data;
      if (raw == null || raw is! Map) return heuristic;

      final m = Map<String, dynamic>.from(raw);
      final short = _str(m, 'aiSummaryShortTr', 'ai_summary_short_tr');
      if (short == null || short.isEmpty) return heuristic;

      final out = PostCallAiEnrichment(
        aiSummaryShortTr: short,
        aiCustomerMoodTr:
            _str(m, 'aiCustomerMoodTr', 'ai_customer_mood_tr') ?? heuristic.aiCustomerMoodTr,
        aiObjectionTypeTr:
            _str(m, 'aiObjectionTypeTr', 'ai_objection_type_tr') ?? heuristic.aiObjectionTypeTr,
        aiFollowUpStyleTr:
            _str(m, 'aiFollowUpStyleTr', 'ai_follow_up_style_tr') ?? heuristic.aiFollowUpStyleTr,
        aiBrokerNoteTr:
            _str(m, 'aiBrokerNoteTr', 'ai_broker_note_tr') ?? heuristic.aiBrokerNoteTr,
        source: PostCallAiEnrichmentSource.cloud,
        enrichmentInputMode: input.mode,
      );
      AiGate.markPostCallRemoteSuccess(input);
      return out;
    } on FirebaseFunctionsException catch (e, st) {
      AppLogger.w('enrichPostCallSummary unavailable: ${e.code} ${e.message}', st);
      return heuristic;
    } catch (e, st) {
      AppLogger.w('PostCallAiEnrichmentService: $e', st);
      return heuristic;
    }
  }

  static String? _str(Map<String, dynamic> m, String a, String b) {
    final v = m[a] ?? m[b];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
