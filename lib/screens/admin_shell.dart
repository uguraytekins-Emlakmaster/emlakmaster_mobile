import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/pages/command_center_page.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/pages/war_room_page.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_return_prompt_host.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_strip.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_draft_recovery_card.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:emlakmaster_mobile/screens/dashboard_screen.dart';
import 'package:emlakmaster_mobile/features/messages/presentation/pages/message_center_page.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:emlakmaster_mobile/screens/admin_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici paneli: tam yetki. Nav öğeleri ayarlardaki özellik bayraklarına göre gösterilir.
enum _AdminShellTab {
  dashboard,
  messages,
  warRoom,
  commandCenter,
  economy,
  reports,
  settings,
}

class _AdminShellTabEntry {
  const _AdminShellTabEntry({
    required this.id,
    required this.navItem,
    required this.page,
  });

  final _AdminShellTab id;
  final AdaptiveNavItem navItem;
  final Widget page;
}

class AdminShellPage extends ConsumerStatefulWidget {
  const AdminShellPage({super.key});

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  int _shellPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final lean = flags?[AppConstants.keyV1LeanProduct] ?? true;
    final warRoom = (flags?[AppConstants.keyFeatureWarRoom] ?? true) && !lean;
    final commandCenterFlag =
        flags?[AppConstants.keyFeatureCommandCenter] ?? true;

    /// [CommandCenterPage] ile aynı kural: yalnızca global çağrı görünümü (broker_owner / super_admin).
    final roleAsync = ref.watch(displayRoleProvider);
    final showCommandCenter = commandCenterFlag &&
        roleAsync.maybeWhen(
          data: (r) => FeaturePermission.canViewAllCalls(r),
          orElse: () => false,
        );
    final showEconomyTab = !lean;
    final entries = <_AdminShellTabEntry>[
      const _AdminShellTabEntry(
        id: _AdminShellTab.dashboard,
        navItem:
            AdaptiveNavItem(Icons.dashboard_rounded, ProductLabels.managerHome),
        page: DashboardPage(),
      ),
      const _AdminShellTabEntry(
        id: _AdminShellTab.messages,
        navItem: AdaptiveNavItem(
          Icons.forum_rounded,
          ProductLabels.messageCenter,
        ),
        page: MessageCenterPage(),
      ),
      if (warRoom)
        const _AdminShellTabEntry(
          id: _AdminShellTab.warRoom,
          navItem: AdaptiveNavItem(
            Icons.military_tech_rounded,
            ProductLabels.warRoom,
          ),
          page: WarRoomPage(),
        ),
      if (showCommandCenter)
        const _AdminShellTabEntry(
          id: _AdminShellTab.commandCenter,
          navItem: AdaptiveNavItem(
            Icons.call_rounded,
            ProductLabels.callCenter,
          ),
          page: CommandCenterPage(),
        ),
      if (showEconomyTab)
        const _AdminShellTabEntry(
          id: _AdminShellTab.economy,
          navItem: AdaptiveNavItem(Icons.trending_up_rounded, 'Ekonomi'),
          page: AdminEconomyPage(),
        ),
      const _AdminShellTabEntry(
        id: _AdminShellTab.reports,
        navItem:
            AdaptiveNavItem(Icons.analytics_rounded, ProductLabels.reports),
        page: AdminReportsPage(),
      ),
      const _AdminShellTabEntry(
        id: _AdminShellTab.settings,
        navItem:
            AdaptiveNavItem(Icons.settings_rounded, ProductLabels.settings),
        page: SettingsPage(),
      ),
    ];
    final navItems =
        entries.map((entry) => entry.navItem).toList(growable: false);
    final pages = entries.map((entry) => entry.page).toList(growable: false);
    final tabIds = entries.map((entry) => entry.id).toList(growable: false);
    final settingsIndex =
        tabIds.indexOf(_AdminShellTab.settings).clamp(0, tabIds.length - 1);
    final messagesIndex =
        tabIds.indexOf(_AdminShellTab.messages).clamp(0, tabIds.length - 1);
    final commandCenterPageIndex = tabIds.indexOf(_AdminShellTab.commandCenter);
    assert(
      navItems.length == pages.length,
      'AdminShell: navItems (${navItems.length}) and pages (${pages.length}) must stay in sync',
    );
    if (kDebugMode) {
      AppLogger.state(
        '[startup][AdminShell] tabs=${navItems.length} lean=$lean warRoom=$warRoom '
        'commandCenter=$showCommandCenter economy=$showEconomyTab ids=$tabIds',
      );
    }
    // ÖNEMLİ: [ValueKey] ile kabuk sıfırlamayın — [featureFlagsProvider] / [displayRoleProvider]
    // her yeniden build'de hash değişince yeni [AdaptiveShellScaffoldState] oluşur; [_currentIndex]
    // sürekli 0'a döner ve alt sekme dokunuşları Dashboard'ta kalır (P0 gerçek cihaz).
    return Column(
      children: [
        const SyncStatusBanner(compact: true),
        const CallReturnPromptHost(),
        const PostCallDraftRecoveryCard(),
        if (commandCenterPageIndex < 0 ||
            _shellPageIndex != commandCenterPageIndex)
          const PostCallCaptureShellStrip(),
        Expanded(
          child: AdaptiveShellScaffold(
            navItems: navItems,
            pages: pages,
            tabIds: tabIds,
            title: ProductLabels.managerWorkspace,
            onIndexChanged: (i) {
              if (_shellPageIndex != i) {
                setState(() => _shellPageIndex = i);
              }
            },
            shortcutMap: {
              MainShellShortcut.openHomeTab: 0,
              MainShellShortcut.openMessageCenterTab: messagesIndex,
              MainShellShortcut.openAccountTab: settingsIndex,
            },
          ),
        ),
      ],
    );
  }
}
