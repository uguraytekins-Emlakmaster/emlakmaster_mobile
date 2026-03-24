import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_repository.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_service.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listings_repository.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tek kaynak: yerel import motoru + görev geçmişi.
final listingImportServiceProvider = Provider<ListingImportService>(
  (ref) => ListingImportService.instance,
);

/// Alias — spec adı.
final listingImportProvider = listingImportServiceProvider;

/// Benim ilanlarım (import edilenler).
final myListingsProvider = StreamProvider<List<ListingEntity>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<List<ListingEntity>>.value(const []);
  }
  return ListingsRepository.instance.watchForOwner(uid);
});

/// Import görev geçmişi.
final importHistoryProvider = StreamProvider<List<ListingImportTaskEntity>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<List<ListingImportTaskEntity>>.value(const []);
  }
  return ListingImportRepository.instance.streamForOwner(uid);
});

/// Geriye dönük uyumluluk.
final listingImportTasksProvider = importHistoryProvider;
