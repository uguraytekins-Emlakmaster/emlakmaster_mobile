import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/back_navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Merkezi geri: route → sekme içi → [onShellBack] → çıkış.
class AppBackDispatcher {
  AppBackDispatcher._();

  /// Uygulama içi geri düğmesi.
  static Future<bool> tryPop(
    BuildContext context, {
    bool Function()? onShellBack,
  }) async {
    AppFeedback.lightImpact();

    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
      return true;
    }

    if (context.canPop()) {
      context.pop();
      return true;
    }

    if (BackNavigationScope.maybeHandle(context)) {
      return true;
    }

    if (onShellBack != null && onShellBack()) {
      return true;
    }

    return false;
  }

  /// Kabuk kökünde sistem geri (Android).
  static Future<bool> handleShellSystemBack(
    BuildContext context, {
    required bool Function() tryPopTab,
    required VoidCallback onExitApp,
  }) async {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
      return true;
    }

    if (context.canPop()) {
      context.pop();
      return true;
    }

    if (BackNavigationScope.maybeHandle(context)) {
      return true;
    }

    if (tryPopTab()) {
      return true;
    }

    onExitApp();
    return true;
  }
}
