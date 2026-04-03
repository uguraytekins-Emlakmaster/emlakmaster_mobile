import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/pages/consultant_calls_page.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard_page.dart';
import 'package:emlakmaster_mobile/screens/consultant_resurrection_page.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:emlakmaster_mobile/screens/listings_screen.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
/// Danışman paneli: özetim, müşteriler, ilanlar, takip, görevler, ayarlar.
/// Web/Desktop: sidebar; Mobile: bottom nav. Magic Call: Özetim üzerindeki birincil aksiyon bloğu.
class ConsultantShellPage extends StatelessWidget {
  const ConsultantShellPage({super.key});

  static const List<AdaptiveNavItem> _navItems = [
    AdaptiveNavItem(Icons.dashboard_rounded, 'Özetim'),
    AdaptiveNavItem(Icons.call_rounded, 'Çağrılar'),
    AdaptiveNavItem(Icons.people_rounded, 'Müşterilerim'),
    AdaptiveNavItem(Icons.home_work_rounded, 'İlanlar'),
    AdaptiveNavItem(Icons.replay_rounded, 'Takip'),
    AdaptiveNavItem(Icons.task_alt_rounded, 'Görevler'),
    AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
  ];

  static const List<Widget> _pages = [
    ConsultantDashboardPage(),
    ConsultantCallsPage(),
    CustomerListPage(),
    ListingsPage(),
    ConsultantResurrectionPage(),
    TasksPage(),
    SettingsPage(),
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
            title: 'Danışman Paneli',
          ),
        ),
      ],
    );
  }
}
