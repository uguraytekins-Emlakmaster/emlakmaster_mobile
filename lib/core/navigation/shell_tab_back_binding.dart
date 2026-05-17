import 'package:emlakmaster_mobile/core/navigation/back_navigation_scope.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_host.dart';
import 'package:flutter/material.dart';

/// Aktif sekme sayfasının geri önceliğini kabuğa bildirir (arama, seçim, filtre).
class ShellTabBackBinding extends StatefulWidget {
  const ShellTabBackBinding({
    super.key,
    required this.child,
    this.onExitSearch,
    this.onClearSelection,
    this.onCloseFilters,
    this.onCustomBack,
  });

  final Widget child;
  final BackNavigationCallback? onExitSearch;
  final BackNavigationCallback? onClearSelection;
  final BackNavigationCallback? onCloseFilters;
  final BackNavigationCallback? onCustomBack;

  @override
  State<ShellTabBackBinding> createState() => ShellTabBackBindingState();
}

class ShellTabBackBindingState extends State<ShellTabBackBinding> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _publish();
  }

  @override
  void didUpdateWidget(covariant ShellTabBackBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publish();
  }

  @override
  void dispose() {
    ShellTabBackHost.maybeOf(context)?.detachBinding(this);
    super.dispose();
  }

  void _publish() {
    ShellTabBackHost.maybeOf(context)?.attachBinding(this);
  }

  /// Kabuk / [AppBackDispatcher] için öncelikli geri zinciri.
  bool handleBack() {
    final steps = <BackNavigationCallback?>[
      _dismissKeyboard,
      widget.onExitSearch,
      widget.onClearSelection,
      widget.onCloseFilters,
      widget.onCustomBack,
    ];
    for (final step in steps) {
      if (step != null && step()) return true;
    }
    return false;
  }

  bool _dismissKeyboard() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BackNavigationScope(
      onDismissKeyboard: _dismissKeyboard,
      onExitSearch: widget.onExitSearch,
      onClearSelection: widget.onClearSelection,
      onCloseFilters: widget.onCloseFilters,
      onCustomBack: widget.onCustomBack,
      child: widget.child,
    );
  }
}
