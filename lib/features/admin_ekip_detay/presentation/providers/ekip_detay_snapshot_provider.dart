import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/providers/admin_teams_providers.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/providers/admin_office_health_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekip detay — mevcut stream'leri birleştirir; ek Firestore okuması yok.
final ekipDetaySnapshotProvider = Provider.autoDispose
    .family<AsyncValue<EkipDetaySnapshot>, String>((ref, teamId) {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  final includeOffice = role.isManagerTier;

  final teamAsync = ref.watch(adminTeamDocProvider(teamId));
  final consultantsAsync = ref.watch(adminConsultantsListProvider);
  final cmdAsync =
      includeOffice ? ref.watch(adminCommandSnapshotProvider) : null;

  if (teamAsync.isLoading || consultantsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (teamAsync.hasError) {
    return AsyncValue.error(
      teamAsync.error!,
      teamAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (consultantsAsync.hasError) {
    return AsyncValue.error(
      consultantsAsync.error!,
      consultantsAsync.stackTrace ?? StackTrace.empty,
    );
  }

  if (includeOffice && cmdAsync != null && cmdAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final team = teamAsync.valueOrNull;
  if (team == null) {
    return const AsyncValue.error('team_not_found', StackTrace.empty);
  }

  final office = includeOffice && cmdAsync?.hasError != true
      ? (cmdAsync?.valueOrNull?.health ?? AdminOfficeHealthSummary.empty)
      : AdminOfficeHealthSummary.empty;

  return AsyncValue.data(
    computeEkipDetaySnapshot(
      team: team,
      consultants: consultantsAsync.value ?? const [],
      office: office,
      includeOfficeSignals: includeOffice && cmdAsync?.hasError != true,
    ),
  );
});
