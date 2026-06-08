import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/data/war_room_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/utils/war_room_intervention_model.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_command_center.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_resurrection_strip.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/unauthorized_screen.dart';

/// Role-Based War Room: kritik operasyon müdahale merkezi.
class WarRoomPage extends ConsumerWidget {
  const WarRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gerçek rol (override DEĞİL): danışman görünümüne geçen yönetici hâlâ
    // yetkilidir; ancak rol override'ı bir agent'ı buraya yükseltemez.
    final roleAsync = ref.watch(currentRoleProvider);
    return roleAsync.when(
      loading: () {
        final premium = PremiumThemeExtension.of(context);
        return PremiumShellBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: premium.champagneGold),
            ),
          ),
        );
      },
      error: (_, __) => UnauthorizedScreen(
        message: AppLocalizations.of(context).t('war_room_role_error'),
      ),
      data: (role) {
        if (!FeaturePermission.canViewWarRoom(role)) {
          return UnauthorizedScreen(
            message: AppLocalizations.of(context).t('war_room_no_access'),
          );
        }
        return const _WarRoomBody();
      },
    );
  }
}

class _WarRoomBody extends ConsumerWidget {
  const _WarRoomBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TourTarget(
                  id: TourTargetId.managerWarRoom,
                  child: ShellScreenReadyListener(
                    screenName: 'war_room',
                    provider: warRoomInterventionSnapshotProvider,
                    itemCount: (v) =>
                        (v as WarRoomInterventionSnapshot).interventions.length,
                    child: const WarRoomCommandCenter(),
                  ),
                ),
              ),
              const WarRoomResurrectionStrip(),
            ],
          ),
        ),
      ),
    );
  }
}
