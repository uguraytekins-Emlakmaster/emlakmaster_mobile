import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/calls/data/transcript_ingestion_adapter.dart';
import 'package:emlakmaster_mobile/features/calls/domain/transcript_ingest_payload.dart';

/// v1: [FirestoreService.mergeCustomerLastCallTranscript] — telefon boru hattı gerekmez.
class FirestoreTranscriptIngestionAdapter implements TranscriptIngestionAdapter {
  const FirestoreTranscriptIngestionAdapter();

  static const FirestoreTranscriptIngestionAdapter instance = FirestoreTranscriptIngestionAdapter();

  @override
  Future<void> mergeIntoCustomer({
    required String customerId,
    required TranscriptIngestPayload payload,
  }) async {
    if (customerId.isEmpty) return;
    final snap = payload.toCallTranscriptSnapshot();
    final text = snap.rawTranscriptText;
    if (text == null || text.isEmpty) return;
    await FirestoreService.mergeCustomerLastCallTranscript(
      customerId,
      snap.toFirestoreMap(),
    );
  }
}
