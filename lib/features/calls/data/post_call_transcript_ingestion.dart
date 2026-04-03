import 'package:emlakmaster_mobile/features/calls/data/firestore_transcript_ingestion_adapter.dart';
import 'package:emlakmaster_mobile/features/calls/data/transcript_ingestion_adapter.dart';
import 'package:emlakmaster_mobile/features/calls/domain/transcript_ingest_payload.dart';

/// Post-call ve gelecek STT yolları için tek cephe — `lastCallTranscript` merge (özet alanına dokunmaz).
class PostCallTranscriptIngestion {
  PostCallTranscriptIngestion._();

  static const TranscriptIngestionAdapter _defaultAdapter = FirestoreTranscriptIngestionAdapter.instance;

  /// Test veya özel depolama için enjekte edilebilir varsayılan.
  static TranscriptIngestionAdapter get defaultAdapter => _defaultAdapter;

  /// Yapılandırılmış girdi; tüm kaynaklar buradan geçmeli.
  ///
  /// Boş metin no-op. Hata yutulmaz — çağıran kayıt akışını korumak için try/catch kullanır.
  static Future<void> mergePayloadIfPresent({
    required String customerId,
    required TranscriptIngestPayload payload,
    TranscriptIngestionAdapter? adapter,
  }) async {
    final a = adapter ?? _defaultAdapter;
    await a.mergeIntoCustomer(customerId: customerId, payload: payload);
  }

  /// Manuel yapıştırma — [TranscriptIngestPayload.manual] kısayolu.
  static Future<void> mergeManualTranscriptIfPresent({
    required String customerId,
    required String rawTranscriptText,
  }) async {
    final t = rawTranscriptText.trim();
    if (t.isEmpty || customerId.isEmpty) return;
    await mergePayloadIfPresent(
      customerId: customerId,
      payload: TranscriptIngestPayload.manual(rawTranscriptText: t),
    );
  }

  /// On-device / kontrollü STT metin el sıkışması — [TranscriptSource.localSpeechToText].
  /// Gerçek mikrofon entegrasyonu bu fabrikayı kullanır; özet akışını değiştirmez.
  static Future<void> mergeSpeechToTextHandoffIfPresent({
    required String customerId,
    required String rawTranscriptText,
    String transcriptLanguage = 'tr',
    double? transcriptConfidence,
    String? externalReferenceId,
    Map<String, String> sourceMetadata = const {},
  }) async {
    final t = rawTranscriptText.trim();
    if (t.isEmpty || customerId.isEmpty) return;
    await mergePayloadIfPresent(
      customerId: customerId,
      payload: TranscriptIngestPayload.speechToTextHandoff(
        rawTranscriptText: t,
        transcriptLanguage: transcriptLanguage,
        transcriptConfidence: transcriptConfidence,
        externalReferenceId: externalReferenceId,
        sourceMetadata: sourceMetadata,
      ),
    );
  }
}
