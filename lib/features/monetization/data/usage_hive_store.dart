import 'dart:convert';

import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/monetization/domain/usage_tracker.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UsageHiveStore {
  UsageHiveStore._();

  static final UsageHiveStore instance = UsageHiveStore._();

  static const String boxName = 'usage_tracker_v1';

  Box<String>? _box;
  bool _initDone = false;

  Future<void> ensureInit() async {
    if (_initDone) return;
    try {
      await AppCacheService.instance.ensureInit();
      if (!Hive.isBoxOpen(boxName)) {
        _box = await Hive.openBox<String>(boxName);
      } else {
        _box = Hive.box<String>(boxName);
      }
      _initDone = true;
    } catch (e, st) {
      AppLogger.e('UsageHiveStore init', e, st);
    }
  }

  Future<UsageTracker?> getUsage(String userId) async {
    await ensureInit();
    final raw = _box?.get(userId);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return UsageTracker.tryParse(
        Map<String, dynamic>.from(jsonDecode(raw) as Map<dynamic, dynamic>),
      );
    } catch (e, st) {
      AppLogger.w('UsageHiveStore getUsage', e, st);
      return null;
    }
  }

  Future<void> saveUsage(UsageTracker usage) async {
    await ensureInit();
    await _box?.put(usage.userId, jsonEncode(usage.toJson()));
  }

  Future<UsageTracker> resetIfNewPeriod(
    UsageTracker usage, {
    DateTime? now,
  }) async {
    final stamp = now ?? DateTime.now();
    if (stamp.difference(usage.periodStart) < const Duration(days: 30)) {
      return usage;
    }
    final reset = UsageTracker.initial(
      userId: usage.userId,
      isPro: usage.isPro,
      now: stamp,
    );
    await saveUsage(reset);
    return reset;
  }

  Future<UsageTracker> incrementCall(UsageTracker usage) async {
    final next = usage.copyWith(callsThisMonth: usage.callsThisMonth + 1);
    await saveUsage(next);
    return next;
  }

  Future<UsageTracker> incrementAi(UsageTracker usage) async {
    final next = usage.copyWith(aiUsageThisMonth: usage.aiUsageThisMonth + 1);
    await saveUsage(next);
    return next;
  }

  Future<UsageTracker> incrementCustomer(UsageTracker usage) async {
    final next = usage.copyWith(customersTracked: usage.customersTracked + 1);
    await saveUsage(next);
    return next;
  }
}
