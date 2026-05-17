import 'package:emlakmaster_mobile/core/layout/adaptive_shell_scaffold.dart';
import 'package:emlakmaster_mobile/core/navigation/back_navigation_scope.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:flutter/material.dart';

/// Sekme sayfasını kabuk geri zincirine bağlar (yalnızca aktif sekme).
class ShellTabBackHost extends StatefulWidget {
  const ShellTabBackHost({
    super.key,
    required this.pageIndex,
    required this.child,
  });

  final int pageIndex;
  final Widget child;

  static ShellTabBackHostState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ShellTabBackHostState>();
  }

  @override
  State<ShellTabBackHost> createState() => ShellTabBackHostState();
}

class ShellTabBackHostState extends State<ShellTabBackHost> {
  ShellTabBackBindingState? _binding;
  AdaptiveShellScaffoldState? _shell;

  void attachBinding(ShellTabBackBindingState binding) {
    _binding = binding;
    _syncShellHandler();
  }

  void detachBinding(ShellTabBackBindingState binding) {
    if (_binding != binding) return;
    _binding = null;
    _shell?.registerTabBackHandler(widget.pageIndex, null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shell = context.findAncestorStateOfType<AdaptiveShellScaffoldState>();
    _syncShellHandler();
  }

  @override
  void didUpdateWidget(covariant ShellTabBackHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncShellHandler();
  }

  @override
  void dispose() {
    _shell?.registerTabBackHandler(widget.pageIndex, null);
    super.dispose();
  }

  void _syncShellHandler() {
    final shell = _shell;
    if (shell == null) return;
    if (shell.activeTabIndex == widget.pageIndex) {
      shell.registerTabBackHandler(widget.pageIndex, _handleTabBack);
    } else {
      shell.registerTabBackHandler(widget.pageIndex, null);
    }
  }

  bool _handleTabBack() {
    final binding = _binding;
    if (binding != null && binding.mounted) {
      return binding.handleBack();
    }
    return BackNavigationScope.maybeHandle(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
