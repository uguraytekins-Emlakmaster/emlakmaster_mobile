import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/back_navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Merkezi geri: route → Navigator yığını → sekme içi → [onShellBack] → çıkış.
class AppBackDispatcher {
  AppBackDispatcher._();

  static bool _routerCanPop(BuildContext context) {
    try {
      return GoRouter.of(context).canPop();
    } catch (_) {
      return false;
    }
  }

  /// Yalnızca gerçek bir metin girişi (klavye) odaktaysa true.
  ///
  /// `primaryFocus.hasFocus`, metin alanı olmasa bile rotanın FocusScope'u
  /// odakta olduğu için neredeyse her zaman true döner; bu yüzden geri
  /// basışını yutmamak için odağın bir [EditableText] olup olmadığını
  /// kontrol ederiz.
  static bool _dismissKeyboardIfOpen() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return false;
    if (focus.context?.widget is! EditableText) return false;
    focus.unfocus();
    return true;
  }

  /// go_router veya üstüne eklenen [Navigator.push] rotası kapatılabilir mi?
  static bool canPopRoute(BuildContext context) {
    if (_routerCanPop(context)) return true;
    final nav = Navigator.maybeOf(context);
    return nav != null && nav.canPop();
  }

  /// Önce go_router, sonra yerel Navigator (MaterialPageRoute vb.).
  static bool popRoute(BuildContext context) {
    if (_routerCanPop(context)) {
      context.pop();
      return true;
    }
    final nav = Navigator.maybeOf(context);
    if (nav != null && nav.canPop()) {
      nav.pop();
      return true;
    }
    return false;
  }

  /// Uygulama içi geri düğmesi.
  static Future<bool> tryPop(
    BuildContext context, {
    bool Function()? onShellBack,
  }) async {
    AppFeedback.lightImpact();

    if (_dismissKeyboardIfOpen()) {
      return true;
    }

    if (popRoute(context)) {
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
    if (_dismissKeyboardIfOpen()) {
      return true;
    }

    if (popRoute(context)) {
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
