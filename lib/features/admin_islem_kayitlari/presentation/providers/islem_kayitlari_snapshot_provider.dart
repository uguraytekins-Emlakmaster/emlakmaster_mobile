import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/data/audit_log_repository.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// İşlem Kayıtları — audit_logs + davet kayıtları tek snapshot.
final islemKayitlariSnapshotProvider =
    Provider.autoDispose<AsyncValue<IslemKayitlariPageSnapshot>>((ref) {
  final auditAsync = ref.watch(auditLogsStreamProvider);
  final invitesAsync = ref.watch(adminInvitesStreamProvider);
  final consultantsAsync = ref.watch(adminConsultantsListProvider);

  if (auditAsync.isLoading ||
      invitesAsync.isLoading ||
      consultantsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (auditAsync.hasError) {
    return AsyncValue.error(
      auditAsync.error!,
      auditAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (invitesAsync.hasError) {
    return AsyncValue.error(
      invitesAsync.error!,
      invitesAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (consultantsAsync.hasError) {
    return AsyncValue.error(
      consultantsAsync.error!,
      consultantsAsync.stackTrace ?? StackTrace.empty,
    );
  }

  return AsyncValue.data(
    computeIslemKayitlariSnapshot(
      auditLogs: auditAsync.value ?? const [],
      invites: invitesAsync.value ?? const [],
      consultants: consultantsAsync.value ?? const [],
      now: DateTime.now(),
    ),
  );
});
