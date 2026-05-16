import 'package:flutter/material.dart';

/// Danışman kabuğu içinde alt sekmeye programatik geçiş (ör. özet kartından).
class ConsultantShellNav extends InheritedWidget {
  const ConsultantShellNav({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final void Function(int index) goToTab;

  static ConsultantShellNav? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConsultantShellNav>();
  }

  /// [pages] indeks 0 — Günüm.
  static void goToHomeTab(BuildContext context) {
    maybeOf(context)?.goToTab(0);
  }

  /// [pages] indeks 1 — Mesaj Merkezi (Daha Fazla).
  static void goToMessageCenterTab(BuildContext context) {
    maybeOf(context)?.goToTab(1);
  }

  /// [pages] indeks 3 — Müşterilerim.
  static void goToCustomersTab(BuildContext context) {
    maybeOf(context)?.goToTab(3);
  }

  /// [pages] indeks 2 — Çağrılarım.
  static void goToCallsTab(BuildContext context) {
    maybeOf(context)?.goToTab(2);
  }

  /// [pages] indeks 6 — Görevlerim.
  static void goToTasksTab(BuildContext context) {
    maybeOf(context)?.goToTab(6);
  }

  @override
  bool updateShouldNotify(covariant ConsultantShellNav oldWidget) => false;
}
