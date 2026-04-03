import 'package:emlakmaster_mobile/features/calls/domain/transcript_ingest_payload.dart';

/// Transkripti müşteri kaydına yazar; STT, dosya veya manuel girdi aynı sözleşmeyi kullanır.
abstract class TranscriptIngestionAdapter {
  /// Boş [TranscriptIngestPayload.rawTranscriptText] için no-op.
  /// [customerId] boşsa no-op.
  Future<void> mergeIntoCustomer({
    required String customerId,
    required TranscriptIngestPayload payload,
  });
}
