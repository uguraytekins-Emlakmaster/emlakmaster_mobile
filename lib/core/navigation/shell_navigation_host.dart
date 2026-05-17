import 'package:flutter/material.dart';

/// [AdaptiveShellScaffold] tarafından sağlanır — sekme geri ve çıkış.
class ShellNavigationHost extends InheritedWidget {
  const ShellNavigationHost({
    super.key,
    required this.onShellSystemBack,
    required super.child,
  });

  final Future<void> Function() onShellSystemBack;

  static ShellNavigationHost? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ShellNavigationHost>();
  }

  @override
  bool updateShouldNotify(ShellNavigationHost oldWidget) =>
      onShellSystemBack != oldWidget.onShellSystemBack;
}
