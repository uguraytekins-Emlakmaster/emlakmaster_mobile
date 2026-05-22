import 'package:flutter/material.dart';

/// Yönetici kabuğu içinde programatik sekme geçişi.
class AdminShellNav extends InheritedWidget {
  const AdminShellNav({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final void Function(int pageIndex) goToTab;

  static AdminShellNav? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminShellNav>();
  }

  static void goToHomeTab(BuildContext context) {
    maybeOf(context)?.goToTab(0);
  }

  @override
  bool updateShouldNotify(covariant AdminShellNav oldWidget) => false;
}
