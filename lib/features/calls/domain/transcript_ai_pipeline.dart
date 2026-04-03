import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment_input.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';

/// Gelecekte: ham transkript → zengin özet + broker notu + ton / itiraz / takip stili.
///
/// **Post-call v1:** [PostCallAiEnrichmentService] özet + isteğe bağlı transkripti birleştirir;
/// bu arayüz **transkript-odaklı** ayrı çağrılar (ör. yalnız STT çıktısı) için hazırdır.
///
/// Entegrasyon seçenekleri (sonra):
/// - Cloud Function `enrichFromTranscript` (API anahtarı sunucuda)
/// - İstemci sadece metin + dil gönderir; çıktı [PostCallAiEnrichment] ile uyumlu map
abstract class TranscriptAiPipeline {
  /// Transkriptten türetilmiş zenginleştirme; yoksa null (çağıran sezgisel / mevcut yolu kullanır).
  Future<PostCallAiEnrichment?> deriveEnrichment({
    required String rawTranscriptText,
    String? transcriptLanguage,
    PostCallCrmSignals? signals,
  });
}

/// v1: sezgisel zenginleştirme — [computeHeuristicPostCallAiEnrichment] ile aynı aile (deterministik CRM’e dokunmaz).
class HeuristicTranscriptAiPipeline implements TranscriptAiPipeline {
  const HeuristicTranscriptAiPipeline();

  static const TranscriptAiPipeline instance = HeuristicTranscriptAiPipeline();

  @override
  Future<PostCallAiEnrichment?> deriveEnrichment({
    required String rawTranscriptText,
    String? transcriptLanguage,
    PostCallCrmSignals? signals,
  }) async {
    final t = rawTranscriptText.trim();
    if (t.isEmpty) return null;
    return computeHeuristicPostCallAiEnrichment(
      input: PostCallAiEnrichmentInput.resolve(
        summary: '',
        transcript: t,
      ),
      signals: signals ?? PostCallCrmSignals.fallback(),
    );
  }
}

/// Test / devre dışı: her zaman null.
class NoOpTranscriptAiPipeline implements TranscriptAiPipeline {
  const NoOpTranscriptAiPipeline();

  static const TranscriptAiPipeline instance = NoOpTranscriptAiPipeline();

  @override
  Future<PostCallAiEnrichment?> deriveEnrichment({
    required String rawTranscriptText,
    String? transcriptLanguage,
    PostCallCrmSignals? signals,
  }) async =>
      null;
}
