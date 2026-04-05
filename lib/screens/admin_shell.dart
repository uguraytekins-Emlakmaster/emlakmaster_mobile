import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/pages/command_center_page.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/pages/war_room_page.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/dashboard_screen.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:emlakmaster_mobile/screens/admin_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici paneli: tam yetki. Nav öğeleri ayarlardaki özellik bayraklarına göre gösterilir.
class AdminShellPage extends ConsumerWidget {
  const AdminShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final lean = flags?[AppConstants.keyV1LeanProduct] ?? true;
    final warRoom = (flags?[AppConstants.keyFeatureWarRoom] ?? true) && !lean;
    final commandCenterFlag = flags?[AppConstants.keyFeatureCommandCenter] ?? true;
    /// [CommandCenterPage] ile aynı kural: yalnızca global çağrı görünümü (broker_owner / super_admin).
    final roleAsync = ref.watch(displayRoleProvider);
    final showCommandCenter = commandCenterFlag &&
        roleAsync.maybeWhen(
          data: (r) => FeaturePermission.canViewAllCalls(r),
          orElse: () => false,
        );
    final showEconomyTab = !lean;
    final navItems = <AdaptiveNavItem>[
      const AdaptiveNavItem(Icons.dashboard_rounded, 'Dashboard'),
      if (warRoom) const AdaptiveNavItem(Icons.military_tech_rounded, 'War Room'),
      if (showCommandCenter) const AdaptiveNavItem(Icons.call_rounded, 'Çağrı Merkezi'),
      if (showEconomyTab) const AdaptiveNavItem(Icons.trending_up_rounded, 'Ekonomi'),
      const AdaptiveNavItem(Icons.analytics_rounded, 'Raporlar'),
      const AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
    ];
    final pages = <Widget>[
      const DashboardPage(),
      if (warRoom) const WarRoomPage(),
      if (showCommandCenter) const CommandCenterPage(),
      if (showEconomyTab) const AdminEconomyPage(),
      const AdminReportsPage(),
      const SettingsPage(),
    ];
    return Column(
      children: [
        const SyncStatusBanner(compact: true),
        Expanded(
          child: AdaptiveShellScaffold(
            navItems: navItems,
            pages: pages,
            title: 'Yönetici Paneli',
          ),
        ),
      ],
    );
  }
}
