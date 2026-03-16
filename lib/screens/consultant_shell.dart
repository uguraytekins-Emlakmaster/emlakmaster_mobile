import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard_page.dart';
import 'package:emlakmaster_mobile/screens/consultant_resurrection_page.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:emlakmaster_mobile/screens/listings_screen.dart';
import 'package:emlakmaster_mobile/screens/placeholder_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli: özetim, müşteriler, ilanlar, takip, görevler, ayarlar.
/// Web/Desktop: sidebar; Mobile: bottom nav + Magic Call FAB (özetim sekmesinde).
class ConsultantShellPage extends StatefulWidget {
  const ConsultantShellPage({super.key});

  @override
  State<ConsultantShellPage> createState() => _ConsultantShellPageState();
}

class _ConsultantShellPageState extends State<ConsultantShellPage> {
  static const List<AdaptiveNavItem> _navItems = [
    AdaptiveNavItem(Icons.dashboard_rounded, 'Özetim'),
    AdaptiveNavItem(Icons.people_rounded, 'Müşterilerim'),
    AdaptiveNavItem(Icons.home_work_rounded, 'İlanlar'),
    AdaptiveNavItem(Icons.replay_rounded, 'Takip'),
    AdaptiveNavItem(Icons.task_alt_rounded, 'Görevler'),
    AdaptiveNavItem(Icons.settings_rounded, 'Ayarlar'),
  ];

  static const List<Widget> _pages = [
    ConsultantDashboardPage(),
    CustomerListPage(),
    ListingsPage(),
    ConsultantResurrectionPage(),
    TasksPage(),
    SettingsPlaceholderPage(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = AdaptiveShellScaffold.isWide(context);
    return Column(
      children: [
        const SyncStatusBanner(compact: true),
        Expanded(
          child: AdaptiveShellScaffold(
            navItems: _navItems,
            pages: _pages,
            title: 'Danışman Paneli',
            onIndexChanged: (i) => setState(() => _currentIndex = i),
            fab: isWide ? null : (_currentIndex == 0 ? const _MagicCallFab() : null),
          ),
        ),
      ],
    );
  }
}

class _MagicCallFab extends StatelessWidget {
  const _MagicCallFab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRouter.routeCall);
        },
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: DesignTokens.primary,
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: DesignTokens.brandWhite, size: 22),
              const SizedBox(width: 10),
              Text(
                'Magic Call & AI Wizard',
                style: TextStyle(
                  color: DesignTokens.brandWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
