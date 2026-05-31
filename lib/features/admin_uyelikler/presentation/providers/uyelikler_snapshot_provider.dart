import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Üyelikler / Davetler — office_invites + office_memberships tek snapshot.
/// officeId ile parametrelenir; isim çözümü için consultant dizini kullanılır.
final uyeliklerSnapshotProvider = Provider.autoDispose
    .family<AsyncValue<UyeliklerPageSnapshot>, String>((ref, officeId) {
  final invitesAsync = ref.watch(officeInvitesStreamProvider(officeId));
  final membersAsync = ref.watch(officeMembersStreamProvider(officeId));
  final directoryAsync = ref.watch(adminConsultantsListProvider);

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
    computeUyeliklerSnapshot(
      invites: invitesAsync.value ?? const [],
      members: membersAsync.value ?? const [],
      // Dizin yüklenmemişse isim çözümü olmadan honest fallback (kısaltılmış uid).
      directory: directoryAsync.valueOrNull ?? const [],
      currentUid: currentUid,
      actorRole: actorRole,
      now: DateTime.now(),
    ),
  );
});
