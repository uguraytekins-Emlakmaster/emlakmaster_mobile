import 'package:emlakmaster_mobile/features/monetization/domain/usage_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free usage thresholds and near-limit flags behave as expected', () {
    final tracker = UsageTracker(
      userId: 'u1',
      callsThisMonth: 40,
      aiUsageThisMonth: 8,
      customersTracked: 24,
      periodStart: DateTime(2026, 4, 1),
      isPro: false,
    );

    expect(tracker.isFree, isTrue);
    expect(tracker.isNearCallLimit, isTrue);
    expect(tracker.isCallLimitReached, isFalse);
    expect(tracker.callUsagePercent, 0.8);
    expect(tracker.isNearAiLimit, isTrue);
    expect(tracker.isNearCustomerLimit, isTrue);
  });

  test('hard limits flip when thresholds are reached', () {
    final tracker = UsageTracker(
      userId: 'u2',
      callsThisMonth: 50,
      aiUsageThisMonth: 10,
      customersTracked: 30,
      periodStart: DateTime(2026, 4, 1),
      isPro: false,
    );

    expect(tracker.isCallLimitReached, isTrue);
    expect(tracker.isAiLimitReached, isTrue);
    expect(tracker.isCustomerLimitReached, isTrue);
  });
}
