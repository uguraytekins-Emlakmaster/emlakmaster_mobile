import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bağlantılar ekranı için çözülen ofis kimliği (retry/invalidate için de gerekli).
final baglantilarOfficeIdProvider = Provider<String>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  final officeFromMem =
      ref.watch(primaryMembershipProvider).valueOrNull?.officeId;
  final officeFromDoc = uid.isEmpty
      ? null
      : ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId;
  return (officeFromMem != null && officeFromMem.isNotEmpty)
      ? officeFromMem
      : (officeFromDoc ?? '');
});

/// Tek türetilmiş snapshot: ham platform listesi + RBAC + kurulum akışı durumu.
/// Yükleme/hata yalnızca ofis bazlı kurulum akışından gelir; katalog her zaman var.
final baglantilarSnapshotProvider =
    Provider<AsyncValue<BaglantilarSnapshot>>((ref) {
  final canManage = ref.watch(canManagePlatformIntegrationsProvider);
  final officeId = ref.watch(baglantilarOfficeIdProvider);
  final setupAsync = ref.watch(platformSetupMapProvider(officeId));
  final platforms = ref.watch(platformListProvider);

  if (officeId.isNotEmpty) {
    if (setupAsync.isLoading) return const AsyncValue.loading();
    if (setupAsync.hasError) {
      return AsyncValue.error(
        setupAsync.error ?? 'unknown',
        setupAsync.stackTrace ?? StackTrace.current,
      );
    }
  }

  return AsyncValue.data(
    computeBaglantilarSnapshot(
      platforms: platforms,
      canManage: canManage,
      officeGrounded: officeId.isNotEmpty,
    ),
  );
});
