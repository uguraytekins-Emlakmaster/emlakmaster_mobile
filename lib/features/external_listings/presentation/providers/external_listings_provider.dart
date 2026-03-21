import 'package:emlakmaster_mobile/features/external_listings/data/external_listings_repository.dart';
import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/providers/listing_display_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ayarlardaki şehir/ilçe ile son atılan harici ilanları stream eder.
final externalListingsStreamProvider =
    StreamProvider<List<ExternalListingEntity>>((ref) {
  final settingsAsync = ref.watch(listingDisplaySettingsProvider);
  final settings = settingsAsync.valueOrNull;
  final cityCode = settings?.cityCode ?? '21';
  final rawDist = settings?.districtName;
  final districtName =
      rawDist != null && rawDist.trim().isNotEmpty ? rawDist.trim() : null;
  return ExternalListingsRepository.streamListings(
    cityCode: cityCode,
    districtName: districtName,
  );
});
