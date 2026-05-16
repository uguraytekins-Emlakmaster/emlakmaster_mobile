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

  /// Mesaj merkezi (indeks 1).
  static void goToMessageCenterTab(BuildContext context) {
    maybeOf(context)?.goToTab(1);
  }

  static void goToCustomersTab(BuildContext context) {
    maybeOf(context)?.goToTab(3);
  }

  /// Çağrılar sekmesi (indeks 2).
  static void goToCallsTab(BuildContext context) {
    maybeOf(context)?.goToTab(2);
  }

  @override
  bool updateShouldNotify(covariant ConsultantShellNav oldWidget) => false;
}
