import 'package:emlakmaster_mobile/core/navigation/unsaved_changes_guard.dart';
import 'package:flutter/material.dart';

/// Modal sheet için PopScope — kayıt formu sheet’leri.
Widget sheetBackWrapper({
  required bool isDirty,
  required Widget child,
  VoidCallback? onAbandon,
}) {
  return UnsavedChangesGuard(
    isDirty: isDirty,
    onPopConfirmed: onAbandon,
    child: child,
  );
}
