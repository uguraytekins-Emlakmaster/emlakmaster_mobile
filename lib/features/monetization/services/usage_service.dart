import 'package:emlakmaster_mobile/features/monetization/domain/usage_tracker.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsageService {
  const UsageService(this.ref);

  final Ref ref;

  Future<void> incrementAiUsage() async {
    await ref.read(usageTrackerProvider.notifier).incrementAi();
  }

  bool canUseCallRecording() {
    return true;
  }

  bool canUseAi() {
    final usage = getCurrentUsage();
    return usage.isPro || !usage.isAiLimitReached;
  }

  bool canTrackCustomer() {
    return true;
  }

  bool shouldShowSoftLimit() {
    final usage = getCurrentUsage();
    return usage.isFree && usage.isNearAiLimit;
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
