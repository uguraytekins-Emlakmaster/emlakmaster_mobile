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

  static void goToCustomersTab(BuildContext context) {
    maybeOf(context)?.goToTab(2);
  }

  /// Çağrılar sekmesi (danışman kabuğunda indeks 1).
  static void goToCallsTab(BuildContext context) {
    maybeOf(context)?.goToTab(1);
  }

  @override
  bool updateShouldNotify(covariant ConsultantShellNav oldWidget) => false;
}
