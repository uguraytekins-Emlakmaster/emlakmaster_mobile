import 'dart:async';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/monetization/data/usage_hive_store.dart';
import 'package:emlakmaster_mobile/features/monetization/domain/usage_tracker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usageTrackerProvider =
    StateNotifierProvider.autoDispose<_UsageTrackerNotifier, UsageTracker>(
        (ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  final office = ref.watch(currentOfficeProvider).valueOrNull;
  final plan = office?.planType.toLowerCase() ?? 'standard';
  final isPro = plan.contains('pro') || plan.contains('premium');
  return _UsageTrackerNotifier(
    store: UsageHiveStore.instance,
    userId: uid,
    isPro: isPro,
  );
});

final shouldShowSoftLimitProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    usageTrackerProvider.select((u) => u.isFree && u.isNearAiLimit),
  );
});

final shouldShowUpgradeNudgeProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    usageTrackerProvider.select(
      (u) => u.isFree && u.aiUsageThisMonth > 8 && !u.isNearAiLimit,
    ),
  );
});

final shouldBlurRevenueInsightsProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(usageTrackerProvider.select((u) => u.isFree));
});

class _UsageTrackerNotifier extends StateNotifier<UsageTracker> {
  _UsageTrackerNotifier({
    required this.store,
    required String userId,
    required bool isPro,
  })  : _userId = userId,
        _isPro = isPro,
        super(UsageTracker.initial(userId: userId, isPro: isPro)) {
    unawaited(_load());
  }

  final UsageHiveStore store;
  final String _userId;
  final bool _isPro;
  bool _loaded = false;

  Future<void> _load() async {
    if (_userId.isEmpty) {
      state = UsageTracker.initial(userId: '', isPro: _isPro);
      _loaded = true;
      return;
    }
    await store.ensureInit();
    final existing = await store.getUsage(_userId);
    final base = existing?.copyWith(isPro: _isPro) ??
        UsageTracker.initial(userId: _userId, isPro: _isPro);
    state = await store.resetIfNewPeriod(base);
    if (state.isPro != _isPro) {
      state = state.copyWith(isPro: _isPro);
      await store.saveUsage(state);
    }
    _loaded = true;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> incrementAi() async {
    await ensureLoaded();
    state = await store.incrementAi(state);
  }
}
