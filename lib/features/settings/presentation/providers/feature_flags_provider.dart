import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _allKeys = [
  AppConstants.keyFeatureVoiceCrm,
  AppConstants.keyFeatureContactSave,
  AppConstants.keyFeatureWarRoom,
  AppConstants.keyFeatureMarketPulse,
  AppConstants.keyFeatureDailyBrief,
  AppConstants.keyFeaturePipeline,
  AppConstants.keyFeatureCommandCenter,
  AppConstants.keyFeatureInvestorIntelligence,
  AppConstants.keyFeatureAnalytics,
  AppConstants.keyFeatureCrashlytics,
  AppConstants.keyFeaturePushNotifications,
  AppConstants.keyFeatureKpiBar,
  AppConstants.keyFeaturePortfolioMatch,
  AppConstants.keyFeatureCallSummary,
  AppConstants.keyFeatureTasks,
  AppConstants.keyFeatureNotificationsCenter,
  AppConstants.keyCompactDashboard,
  AppConstants.keyHapticFeedback,
  AppConstants.keySoundEffects,
  AppConstants.keyPowerSaver,
];

/// Tüm özellik bayrakları tek provider'da; ayar ekranı ve uygulama buradan okur.
final featureFlagsProvider =
    StateNotifierProvider<FeatureFlagsNotifier, AsyncValue<Map<String, bool>>>((ref) {
  return FeatureFlagsNotifier();
});

class FeatureFlagsNotifier extends StateNotifier<AsyncValue<Map<String, bool>>> {
  FeatureFlagsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final map = <String, bool>{};
      for (final key in _allKeys) {
        if (key == AppConstants.keyPowerSaver) {
          map[key] = await SettingsService.instance.getPowerSaverEnabled();
        } else {
          map[key] = await SettingsService.instance.getFeatureFlag(key,
              defaultValue: key == AppConstants.keyCompactDashboard ||
                      key == AppConstants.keySoundEffects
                  ? false
                  : true);
        }
      }
      state = AsyncValue.data(map);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setFlag(String key, bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (key == AppConstants.keyPowerSaver) {
      await SettingsService.instance.setPowerSaverEnabled(value);
      AppLifecyclePowerService.powerSaverEnabled = value;
    } else {
      await SettingsService.instance.setFeatureFlag(key, value);
    }
    state = AsyncValue.data({...current, key: value});
  }

  bool get(String key) =>
      state.valueOrNull?[key] ??
      (key == AppConstants.keyPowerSaver ? false : true);
}
