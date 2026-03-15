import 'package:emlakmaster_mobile/features/market_settings/data/market_settings_repository.dart';
import 'package:emlakmaster_mobile/features/market_settings/domain/entities/market_settings_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketSettingsProvider = StreamProvider<MarketSettingsEntity>((ref) {
  return MarketSettingsRepository.stream();
});

final marketSettingsFutureProvider = FutureProvider<MarketSettingsEntity>((ref) {
  return MarketSettingsRepository.get();
});
