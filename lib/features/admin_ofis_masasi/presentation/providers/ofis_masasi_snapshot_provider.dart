import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ofis Masası — üyeler + davetler + platform kurulumları tek snapshot.
/// officeId ile parametrelenir. Bağlantı kurulum verisi yükleniyor/hatalı ise
/// `setups` null geçilir; sayfa düşmez, bağlantı metrikleri dürüstçe gizlenir.
final ofisMasasiSnapshotProvider = Provider.autoDispose
    .family<AsyncValue<OfisMasasiSnapshot>, String>((ref, officeId) {
  final invitesAsync = ref.watch(officeInvitesStreamProvider(officeId));
  final membersAsync = ref.watch(officeMembersStreamProvider(officeId));
  final directoryAsync = ref.watch(adminConsultantsListProvider);
  final setupsAsync = ref.watch(platformSetupMapProvider(officeId));

  if (invitesAsync.isLoading || membersAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (invitesAsync.hasError) {
    return AsyncValue.error(
      invitesAsync.error!,
      invitesAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (membersAsync.hasError) {
    return AsyncValue.error(
      membersAsync.error!,
      membersAsync.stackTrace ?? StackTrace.empty,
    );
  }

  final currentUid = ref.watch(currentUserProvider).valueOrNull?.uid;
  final actorRole = ref.watch(primaryMembershipProvider).valueOrNull?.role;

  return AsyncValue.data(
    computeOfisMasasiSnapshot(
      invites: invitesAsync.value ?? const [],
      members: membersAsync.value ?? const [],
      directory: directoryAsync.valueOrNull ?? const [],
      // Yükleniyor/hata → null (bağlantı kapsamı bilinmiyor, dürüst gizleme).
      setups: setupsAsync.valueOrNull,
      currentUid: currentUid,
      actorRole: actorRole,
      now: DateTime.now(),
    ),
  );
});
