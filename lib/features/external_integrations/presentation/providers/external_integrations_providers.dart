import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/data/external_connections_repository.dart';
import 'package:emlakmaster_mobile/features/external_integrations/data/integration_listings_repository.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/external_connection_entity.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_synced_listing_entity.dart';

/// Giriş yapmış kullanıcının harici bağlantıları.
final externalConnectionsProvider =
    StreamProvider.autoDispose<List<ExternalConnectionEntity>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(const []);
  }
  return ExternalConnectionsRepository.instance.streamForUser(uid);
});

/// Giriş yapmış kullanıcının harici platformlardan senkron ilanları (`integration_listings`).
final integrationSyncedListingsProvider =
    StreamProvider.autoDispose<List<IntegrationSyncedListingEntity>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(const []);
  }
  return IntegrationListingsRepository.instance.streamForOwner(uid);
});
