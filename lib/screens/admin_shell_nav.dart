import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Yönetici kabuğu içinde programatik sekme geçişi.
class AdminShellNav extends InheritedWidget {
  const AdminShellNav({
    super.key,
    required this.goToTab,
    this.tabIndexFor,
    required super.child,
  });

  final void Function(int pageIndex) goToTab;
  final int Function(String tabKey)? tabIndexFor;

  static AdminShellNav? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminShellNav>();
  }

  static void goToHomeTab(BuildContext context) {
    maybeOf(context)?.goToTab(0);
  }

  static void goToTabKey(BuildContext context, String tabKey) {
    final nav = maybeOf(context);
    if (nav == null) return;
    final idx = nav.tabIndexFor?.call(tabKey) ?? -1;
    if (idx >= 0) nav.goToTab(idx);
  }

  static void goToReportsTab(BuildContext context) =>
      _goToShellTabOrHome(
        context,
        tabKey: 'reports',
        shortcut: MainShellShortcut.openTasksTab,
      );

  static void goToWarRoomTab(BuildContext context) =>
      _goToShellTabOrHome(
        context,
        tabKey: 'warRoom',
        shortcut: MainShellShortcut.openListingsTab,
      );

  static void goToCommandCenterTab(BuildContext context) =>
      _goToShellTabOrHome(
        context,
        tabKey: 'commandCenter',
        shortcut: MainShellShortcut.openCallsTab,
      );

  static void goToMessagesTab(BuildContext context) =>
      goToTabKey(context, 'messages');

  /// Kabuk dışı rota mı — bu rotalardan sekme geçişi önce ana kabuğa dönmeli.
  static bool isOffShellRoute(String path) {
    if (path == AppRouter.routeHome) return false;
    if (path.startsWith('/admin/')) return true;
    if (path == AppRouter.routeCommandCenter) return true;
    if (path == AppRouter.routeWarRoom) return true;
    return false;
  }

  /// İç içe admin rotalarından (ör. /admin/teams) kabuk sekmesine güvenli geçiş.
  static void _goToShellTabOrHome(
    BuildContext context, {
    required String tabKey,
    required MainShellShortcut shortcut,
  }) {
    final path = GoRouter.of(context).state.uri.path;
    final onHomeShell = path == AppRouter.routeHome;

    // Yalnızca zaten ana kabuktayken doğrudan sekme atlayabilir.
    if (onHomeShell) {
      final nav = maybeOf(context);
      if (nav != null) {
        final idx = nav.tabIndexFor?.call(tabKey) ?? -1;
        if (idx >= 0) {
          nav.goToTab(idx);
          return;
        }
      }
    }

    ProviderScope.containerOf(context, listen: false)
        .read(mainShellShortcutProvider.notifier)
        .enqueue(shortcut);

    if (!onHomeShell) {
      context.go(AppRouter.routeHome);
    }
  }

  @override
  bool updateShouldNotify(covariant AdminShellNav oldWidget) =>
      oldWidget.tabIndexFor != tabIndexFor;
}
