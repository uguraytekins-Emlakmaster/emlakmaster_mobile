import 'package:flutter/material.dart';

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
      goToTabKey(context, 'reports');

  static void goToWarRoomTab(BuildContext context) =>
      goToTabKey(context, 'warRoom');

  static void goToMessagesTab(BuildContext context) =>
      goToTabKey(context, 'messages');

  @override
  bool updateShouldNotify(covariant AdminShellNav oldWidget) =>
      oldWidget.tabIndexFor != tabIndexFor;
}
