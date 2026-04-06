import 'package:emlakmaster_mobile/features/monetization/domain/usage_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free ai usage thresholds and near-limit flags behave as expected', () {
    final tracker = UsageTracker(
      userId: 'u1',
      aiUsageThisMonth: 16,
      periodStart: DateTime(2026, 4),
      isPro: false,
    );

    expect(tracker.isFree, isTrue);
    expect(tracker.isNearAiLimit, isTrue);
    expect(tracker.isAiLimitReached, isFalse);
    expect(tracker.aiUsagePercent, 0.8);
  });

  test('ai hard limit flips when threshold is reached', () {
    final tracker = UsageTracker(
      userId: 'u2',
      aiUsageThisMonth: 20,
      periodStart: DateTime(2026, 4),
      isPro: false,
    );

    expect(tracker.isAiLimitReached, isTrue);
  });
}
