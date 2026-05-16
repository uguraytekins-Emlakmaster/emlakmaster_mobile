import 'package:emlakmaster_mobile/features/calls/domain/call_confidence.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_session_reliability.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallSessionReliability', () {
    test('reliable sources include CRM entry points', () {
      expect(
        CallSessionReliability.isReliableHandoffSource('customer_detail'),
        isTrue,
      );
      expect(
        CallSessionReliability.isReliableHandoffSource('consultant_calls'),
        isTrue,
      );
      expect(
        CallSessionReliability.isReliableHandoffSource('identity_sheet_raw_dial'),
        isFalse,
      );
    });

    test('return prompt respects window and flags', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        CallSessionReliability.shouldOfferReturnPrompt(
          createdAtMs: now - 60 * 1000,
          startedFromScreen: 'customer_detail',
          returnPromptShown: false,
          captureCompleted: false,
        ),
        isTrue,
      );
      expect(
        CallSessionReliability.shouldOfferReturnPrompt(
          createdAtMs: now - 60 * 1000,
          startedFromScreen: 'customer_detail',
          returnPromptShown: true,
          captureCompleted: false,
        ),
        isFalse,
      );
      expect(
        CallSessionReliability.shouldOfferReturnPrompt(
          createdAtMs: now - const Duration(hours: 2).inMilliseconds,
          startedFromScreen: 'customer_detail',
          returnPromptShown: false,
          captureCompleted: false,
        ),
        isFalse,
      );
    });

    test('stale draft detection', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(
        CallSessionReliability.isDraftStale(
          now - const Duration(hours: 80).inMilliseconds,
        ),
        isTrue,
      );
      expect(
        CallSessionReliability.isDraftStale(now - const Duration(hours: 1).inMilliseconds),
        isFalse,
      );
    });
  });

  group('CallConfidenceLabels.resolveForRecord', () {
    test('callback badge skipped when memory hint duplicates', () {
      expect(
        CallConfidenceLabels.resolveForRecord(
          outcome: QuickCallOutcome.callbackScheduled,
          memoryHint: 'Geri arama bekliyor',
        ),
        isNull,
      );
    });

    test('reliable handoff shows emlak master badge', () {
      expect(
        CallConfidenceLabels.resolveForRecord(
          startedFromScreen: 'consultant_calls',
          outcome: QuickCallOutcome.reached,
        ),
        CallConfidenceKind.emlakMasterOriginated,
      );
    });

    test('unknown source with no outcome shows manual', () {
      expect(
        CallConfidenceLabels.resolveForRecord(
          startedFromScreen: 'unknown',
          outcome: QuickCallOutcome.noCaptureYet,
        ),
        CallConfidenceKind.manualRecord,
      );
    });
  });
}
