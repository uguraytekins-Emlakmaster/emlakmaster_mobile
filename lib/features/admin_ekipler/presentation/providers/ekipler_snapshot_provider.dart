import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/providers/admin_office_health_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekipler sayfası — mevcut stream'leri birleştirir; ek Firestore okuması yok.
final ekiplerPageSnapshotProvider =
    Provider.autoDispose<AsyncValue<EkiplerPageSnapshot>>((ref) {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  final includeOffice = role.isManagerTier;

  final teamsAsync = ref.watch(adminConsultantsTeamsProvider);
  final consultantsAsync = ref.watch(adminConsultantsListProvider);
  final cmdAsync =
      includeOffice ? ref.watch(adminCommandSnapshotProvider) : null;

  if (teamsAsync.isLoading || consultantsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (teamsAsync.hasError) {
    return AsyncValue.error(
      teamsAsync.error!,
      teamsAsync.stackTrace ?? StackTrace.empty,
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

  final office = includeOffice && cmdAsync?.hasError != true
      ? (cmdAsync?.valueOrNull?.health ?? AdminOfficeHealthSummary.empty)
      : AdminOfficeHealthSummary.empty;

  return AsyncValue.data(
    computeEkiplerPageSnapshot(
      teams: teamsAsync.value ?? const [],
      consultants: consultantsAsync.value ?? const [],
      office: office,
      includeOfficeSignals: includeOffice && cmdAsync?.hasError != true,
    ),
  );
});
