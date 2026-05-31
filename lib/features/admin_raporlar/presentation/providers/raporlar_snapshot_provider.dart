import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/providers/baglantilar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/providers/ofis_masasi_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Raporlar hub — tek türetilmiş snapshot.
/// Yüzeyler RBAC'tan; grounded sayımlar canlı snapshot provider'larından gelir.
/// Grounded kaynaklar yükleniyorsa ilgili sayım sessizce gizlenir (blok yok).
final raporlarSnapshotProvider =
    Provider<AsyncValue<RaporlarSnapshot>>((ref) {
  final roleAsync = ref.watch(displayRoleProvider);
  if (roleAsync.isLoading && !roleAsync.hasValue) {
    return const AsyncValue.loading();
  }
  final role = roleAsync.valueOrNull ?? AppRole.guest;

  final officeId = ref.watch(baglantilarOfficeIdProvider);

  // Grounded sinyaller — yalnızca data varsa kullanılır (honest, non-blocking).
  final teamsCount = ref.watch(adminConsultantsTeamsProvider).valueOrNull?.length;

  final office = ref.watch(ofisMasasiSnapshotProvider(officeId)).valueOrNull;
  final conn = ref.watch(baglantilarSnapshotProvider).valueOrNull;

  final signals = RaporlarGroundedSignals(
    teamsCount: teamsCount,
    officePendingInvites: office?.summary.pendingInvites,
    officeIntervention: office?.summary.interventionCount,
    officeKnown: office != null,
    connectionIntervention: conn?.summary.intervention,
    connectionReady: conn?.summary.ready,
    connectionKnown: conn != null,
  );

  return AsyncValue.data(
    computeRaporlarSnapshot(role: role, signals: signals),
  );
});
