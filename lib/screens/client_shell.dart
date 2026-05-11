import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/sync_status_banner.dart';
import 'package:flutter/material.dart';

import 'client_pages.dart';

/// Müşteri paneli: Arama odaklı, favoriler, mesajlar, sanal tur, profil.
/// Web/Desktop: sidebar. Mobile: thumb-friendly bottom nav.
class ClientShellPage extends StatefulWidget {
  const ClientShellPage({super.key});

  @override
  State<ClientShellPage> createState() => _ClientShellPageState();
}

class _ClientShellPageState extends State<ClientShellPage> {
  static const List<AdaptiveNavItem> _navItems = [
    AdaptiveNavItem(Icons.search_rounded, 'Ara'),
    AdaptiveNavItem(Icons.favorite_rounded, 'Favoriler'),
    AdaptiveNavItem(Icons.chat_rounded, 'Mesajlar'),
    AdaptiveNavItem(Icons.video_camera_back_rounded, 'Sanal Tur'),
    AdaptiveNavItem(Icons.person_rounded, 'Profil'),
  ];

  static const List<Widget> _pages = [
    ClientSearchPage(),
    ClientFavoritesPage(),
    ClientMessagesPage(),
    ClientVirtualTourPage(),
    ClientProfilePage(),
  ];

  static const List<Object> _tabIds = [
    'search',
    'favorites',
    'messages',
    'virtual_tour',
    'profile',
  ];

  @override
  Widget build(BuildContext context) {
    AppLogger.state(
      '[startup][ClientShell] build tabs=${_navItems.length}',
    );
    return const Column(
      children: [
        SyncStatusBanner(compact: true),
        Expanded(
          child: AdaptiveShellScaffold(
            navItems: _navItems,
            pages: _pages,
            tabIds: _tabIds,
            title: 'EmlakMaster',
            shortcutMap: {
              MainShellShortcut.openHomeTab: 0,
              MainShellShortcut.openFavoritesTab: 1,
              MainShellShortcut.openMessagesTab: 2,
              MainShellShortcut.openVirtualTourTab: 3,
              MainShellShortcut.openAccountTab: 4,
            },
          ),
        ),
      ],
    );
  }
}
