import 'package:emlakmaster_mobile/core/navigation/discard_changes_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kaydedilmemiş form — geri / sistem geri önce onay ister.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.onPopConfirmed,
  });

  final bool isDirty;
  final Widget child;
  final VoidCallback? onPopConfirmed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !isDirty) return;
        final leave = await showDiscardChangesDialog(context);
        if (!context.mounted || leave != true) return;
        onPopConfirmed?.call();
        if (context.canPop()) {
          context.pop();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: child,
    );
  }
}
