import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/pages/command_center_page.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/pages/war_room_page.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/dashboard_screen.dart';
import 'package:emlakmaster_mobile/screens/placeholder_pages.dart';
import 'package:emlakmaster_mobile/screens/admin_pages.dart';
import 'package:flutter/material.dart';

/// Yönetici paneli: tam yetki. Web/Desktop: sidebar; Mobile: bottom nav.
/// Dashboard | War Room | Çağrı Merkezi | Ekonomi | Raporlar | Ayarlar
class AdminShellPage extends StatelessWidget {
  const AdminShellPage({super.key});

  static const List<AdaptiveNavItem> _navItems = [
    AdaptiveNavItem(Icons.dashboard_rounded, 'Dashboard'),
    AdaptiveNavItem(Icons.military_tech_rounded, 'War Room'),
    AdaptiveNavItem(Icons.call_rounded, 'Çağrı Merkezi'),
    AdaptiveNavItem(Icons.trending_up_rounded, 'Ekonomi'),
    AdaptiveNavItem(Icons.analytics_rounded, 'Raporlar'),
    AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
  ];

  static const List<Widget> _pages = [
    DashboardPage(),
    WarRoomPage(),
    CommandCenterPage(),
    AdminEconomyPage(),
    AdminReportsPage(),
    SettingsPlaceholderPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SyncStatusBanner(compact: true),
        Expanded(
          child: AdaptiveShellScaffold(
            navItems: _navItems,
            pages: _pages,
            title: 'Yönetici Paneli',
          ),
        ),
      ],
    );
  }
}
