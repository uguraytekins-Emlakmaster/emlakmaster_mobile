import 'package:emlakmaster_mobile/features/listing_display/data/listing_display_settings_repository.dart';
import 'package:emlakmaster_mobile/features/listing_display/domain/entities/listing_display_settings_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingDisplaySettingsProvider =
    StreamProvider<ListingDisplaySettingsEntity>((ref) {
  return ListingDisplaySettingsRepository.stream();
});

final listingDisplaySettingsFutureProvider =
    FutureProvider<ListingDisplaySettingsEntity>((ref) {
  return ListingDisplaySettingsRepository.get();
});
