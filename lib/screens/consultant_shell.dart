import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_return_prompt_host.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_strip.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_draft_recovery_card.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/pages/consultant_calls_page.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/pages/customer_list_page.dart';
import 'package:emlakmaster_mobile/core/performance/startup_shell_chrome.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard_page.dart';
import 'package:emlakmaster_mobile/screens/consultant_more_sheet.dart';
import 'package:emlakmaster_mobile/screens/consultant_resurrection_page.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/pages/tasks_page.dart';
import 'package:emlakmaster_mobile/screens/listings_screen.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/pages/message_center_page.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/consultant_tour_host.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';

/// Danışman paneli: 5 birincil sekme + Daha Fazla menüsü.
/// Tüm sayfalar [IndexedStack] içinde kalır; tabIds ile kimlik sabittir.
class ConsultantShellPage extends StatefulWidget {
  const ConsultantShellPage({super.key});

  @override
  State<ConsultantShellPage> createState() => _ConsultantShellPageState();

  /// Alt menüde görünen 5 öğe (yerelleştirilmiş).
  static List<AdaptiveNavItem> _navItems(AppLocalizations l10n) => [
        AdaptiveNavItem(
            Icons.space_dashboard_rounded, l10n.t('nav_home_consultant')),
        AdaptiveNavItem(Icons.call_rounded, l10n.t('nav_calls')),
        AdaptiveNavItem(Icons.people_rounded, l10n.t('nav_customers')),
        AdaptiveNavItem(Icons.task_alt_rounded, l10n.t('nav_tasks')),
        AdaptiveNavItem(Icons.apps_rounded, l10n.t('nav_more')),
      ];

  /// Alt menü → [pages] indeksi. Son öğe [kShellNavMoreMenu].
  static const List<int> _navPageIndices = [
    0,
    2,
    3,
    6,
    kShellNavMoreMenu,
  ];

  static const List<Widget> _pages = [
    ConsultantDashboardPage(),
    MessageCenterPage(),
    ConsultantCallsPage(),
    CustomerListPage(),
    ListingsPage(),
    ConsultantResurrectionPage(),
    TasksPage(),
    SettingsPage(),
  ];

  static const List<Object> _tabIds = [
    'summary',
    'messages',
    'calls',
    'customers',
    'listings',
    'follow_up',
    'tasks',
    'settings',
  ];
}

class _ConsultantShellPageState extends State<ConsultantShellPage> {
  final GlobalKey<AdaptiveShellScaffoldState> _shellKey =
      GlobalKey<AdaptiveShellScaffoldState>();
  final ValueNotifier<int> _shellPageIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _shellPageIndex.dispose();
    super.dispose();
  }

  void _openMoreSheet() {
    showConsultantMoreSheet(
      context,
      onSelectPage: (pageIndex) => _shellKey.currentState?.jumpToTab(pageIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConsultantShellNav(
      goToTab: (i) => _shellKey.currentState?.jumpToTab(i),
      child: ConsultantTourHost(
        child: Column(
          children: [
            StartupShellChrome(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SyncStatusBanner(compact: true),
                  const CallReturnPromptHost(),
                  const PostCallDraftRecoveryCard(),
                  ValueListenableBuilder<int>(
                    valueListenable: _shellPageIndex,
                    builder: (context, pageIndex, _) {
                      if (pageIndex == 2) return const SizedBox.shrink();
                      return const PostCallCaptureShellStrip();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: AdaptiveShellScaffold(
                key: _shellKey,
                navItems: ConsultantShellPage._navItems(l10n),
                pages: ConsultantShellPage._pages,
                navPageIndices: ConsultantShellPage._navPageIndices,
                onIndexChanged: (i) {
                  if (_shellPageIndex.value != i) {
                    _shellPageIndex.value = i;
                  }
                },
                onMoreNavTap: _openMoreSheet,
                tabIds: ConsultantShellPage._tabIds,
                title: l10n.t('workspace_consultant'),
                shortcutMap: const {
                  MainShellShortcut.openHomeTab: 0,
                  MainShellShortcut.openMessageCenterTab: 1,
                  MainShellShortcut.openCallsTab: 2,
                  MainShellShortcut.openCustomersTab: 3,
                  MainShellShortcut.openListingsTab: 4,
                  MainShellShortcut.openFollowUpTab: 5,
                  MainShellShortcut.openTasksTab: 6,
                  MainShellShortcut.openAccountTab: 7,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
