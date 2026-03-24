import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/pages/consultant_calls_page.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard_page.dart';
import 'package:emlakmaster_mobile/screens/consultant_resurrection_page.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:emlakmaster_mobile/screens/listings_screen.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:emlakmaster_mobile/widgets/magic_call_wizard_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli: özetim, müşteriler, ilanlar, takip, görevler, ayarlar.
/// Web/Desktop: sidebar; Mobile: bottom nav + Magic Call FAB (ayarda açıksa).
class ConsultantShellPage extends ConsumerStatefulWidget {
  const ConsultantShellPage({super.key});

  @override
  ConsumerState<ConsultantShellPage> createState() => _ConsultantShellPageState();
}

class _ConsultantShellPageState extends ConsumerState<ConsultantShellPage> {
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

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = AdaptiveShellScaffold.isWide(context);
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final voiceCrmEnabled = flags?[AppConstants.keyFeatureVoiceCrm] ?? true;
    return Column(
      children: [
        const SyncStatusBanner(compact: true),
        Expanded(
          child: AdaptiveShellScaffold(
            navItems: _navItems,
            pages: _pages,
            title: 'Danışman Paneli',
            onIndexChanged: (i) => setState(() => _currentIndex = i),
            fabLocation: FloatingActionButtonLocation.endFloat,
            fab: isWide
                ? null
                : (_currentIndex == 0 && voiceCrmEnabled
                    ? MagicCallWizardFab(onPressed: () => context.push(AppRouter.routeCall))
                    : null),
          ),
        ),
      ],
    );
  }
}
