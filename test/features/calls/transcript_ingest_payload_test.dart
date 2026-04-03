import 'package:emlakmaster_mobile/features/calls/data/transcript_ingestion_adapter.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_transcript_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/domain/transcript_ingest_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptIngestPayload', () {
    test('manual maps to manual source and ready status', () {
      final p = TranscriptIngestPayload.manual(rawTranscriptText: '  merhaba  ');
      final s = p.toCallTranscriptSnapshot();
      expect(s.rawTranscriptText, 'merhaba');
      expect(s.transcriptSource, TranscriptSource.manual);
      expect(s.transcriptStatus, TranscriptStatus.ready);
    });

    test('speechToTextHandoff uses localSpeechToText and clamps confidence', () {
      final p = TranscriptIngestPayload.speechToTextHandoff(
        rawTranscriptText: 'stt',
        transcriptConfidence: 2.0,
        externalReferenceId: ' job-1 ',
      );
      final s = p.toCallTranscriptSnapshot();
      expect(s.transcriptSource, TranscriptSource.localSpeechToText);
      expect(s.transcriptConfidence, 1.0);
      expect(s.externalReferenceId, 'job-1');
    });

    test('Firestore round-trip for snapshot map', () {
      final p = TranscriptIngestPayload.recordingPipelineJob(
        rawTranscriptText: 'pipeline text',
        externalJobId: 'rec-99',
        sourceMetadata: const {'wave': 'a.wav'},
      );
      final s = p.toCallTranscriptSnapshot();
      final m = s.toFirestoreMap();
      final back = CallTranscriptSnapshot.tryFromFirestoreMap(m);
      expect(back?.rawTranscriptText, 'pipeline text');
      expect(back?.transcriptSource, TranscriptSource.recordingPipeline);
      expect(back?.externalReferenceId, 'rec-99');
      expect(back?.sourceMetadata?['wave'], 'a.wav');
    });
  });

  group('TranscriptIngestionAdapter', () {
    test('fake adapter receives payload', () async {
      final calls = <TranscriptIngestPayload>[];
      final fake = _FakeAdapter(onMerge: calls.add);
      await fake.mergeIntoCustomer(
        customerId: 'c1',
        payload: TranscriptIngestPayload.manual(rawTranscriptText: 'x'),
      );
      expect(calls.length, 1);
      expect(calls.single.transcriptSource, TranscriptSource.manual);
    });

  });
}

class _FakeAdapter implements TranscriptIngestionAdapter {
  _FakeAdapter({required this.onMerge});

  final void Function(TranscriptIngestPayload) onMerge;

  @override
  Future<void> mergeIntoCustomer({
    required String customerId,
    required TranscriptIngestPayload payload,
  }) async {
    onMerge(payload);
  }
}
