import 'package:emlakmaster_mobile/features/monetization/domain/usage_tracker.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsageService {
  const UsageService(this.ref);

  final Ref ref;

  Future<void> incrementCallUsage() async {
    await ref.read(usageTrackerProvider.notifier).incrementCall();
  }

  Future<void> incrementAiUsage() async {
    await ref.read(usageTrackerProvider.notifier).incrementAi();
  }

  Future<void> incrementCustomerUsage() async {
    await ref.read(usageTrackerProvider.notifier).incrementCustomer();
  }

  bool canUseCallRecording() {
    final usage = getCurrentUsage();
    return usage.isPro || !usage.isCallLimitReached;
  }

  bool canUseAi() {
    final usage = getCurrentUsage();
    return usage.isPro || !usage.isAiLimitReached;
  }

  bool canTrackCustomer() {
    final usage = getCurrentUsage();
    return usage.isPro || !usage.isCustomerLimitReached;
  }

  bool shouldShowSoftLimit() {
    final usage = getCurrentUsage();
    return usage.isFree && usage.isNearCallLimit;
  }

  UsageTracker getCurrentUsage() {
    return ref.read(usageTrackerProvider);
  }

  Future<void> warmUp() async {
    await ref.read(usageTrackerProvider.notifier).ensureLoaded();
  }
}

final usageServiceProvider = Provider.autoDispose<UsageService>((ref) {
  return UsageService(ref);
});
