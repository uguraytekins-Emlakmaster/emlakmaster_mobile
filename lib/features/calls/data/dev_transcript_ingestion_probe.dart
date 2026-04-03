import 'package:flutter/foundation.dart';

import 'package:emlakmaster_mobile/features/calls/data/post_call_transcript_ingestion.dart';

/// Debug / test: gerçek telefon veya STT SDK’sı olmadan [mergeSpeechToTextHandoffIfPresent] yolunu çalıştırır.
/// Üretimde çağrılmamalı; UI içermez.
class DevTranscriptIngestionProbe {
  DevTranscriptIngestionProbe._();

  static Future<void> simulateLocalSttWrite({
    required String customerId,
    required String rawTranscriptText,
  }) async {
    if (!kDebugMode) return;
    await PostCallTranscriptIngestion.mergeSpeechToTextHandoffIfPresent(
      customerId: customerId,
      rawTranscriptText: rawTranscriptText,
      transcriptConfidence: 0.9,
      sourceMetadata: const {'channel': 'dev_simulated_stt'},
    );
  }
}
