import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/app_destinations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tek, kabuk-farkındalıklı navigasyon katmanı. Tüm yüzeyler (komut paleti, satır
/// aksiyonları, hızlı rotalar) buradan geçer; böylece davranış tüm rollerde
/// tutarlıdır. Dağınık `enqueue + context.go(routeHome)` kopyaları yerine tek
/// kaynak: kabuktaysak sadece kuyruğa al (route churn yok), değilsek ana kabuğa
/// dön. Ölü buton / yarı-mount kabuk durumu üretmez.
abstract final class ShellNavigator {
  ShellNavigator._();

  /// Kabuk sekmesine güvenli geçiş — herhangi bir yüzeyden çağrılabilir.
  /// Zaten ana kabuktaysak yalnızca kısayolu kuyruğa alır (gereksiz route churn
  /// yok); kabuk dışındaysak kuyruğa alıp [AppRouter.routeHome]'a döner ve kabuk
  /// kuyruğu bir sonraki karede tüketir.
  static void goToShortcut(BuildContext context, MainShellShortcut shortcut) {
    ProviderScope.containerOf(context, listen: false)
        .read(mainShellShortcutProvider.notifier)
        .enqueue(shortcut);

    final path = GoRouter.of(context).state.uri.path;
    if (path != AppRouter.routeHome) {
      context.go(AppRouter.routeHome);
    }
  }

  /// Katalog hedefini aç — kabuk sekmesi kısayolu veya gerçek tam sayfa rotası.
  static void openDestination(BuildContext context, AppDestination destination) {
    switch (destination.nav) {
      case AppDestinationNav.shortcut:
        final shortcut = destination.shortcut;
        if (shortcut != null) goToShortcut(context, shortcut);
      case AppDestinationNav.route:
        final route = destination.route;
        if (route != null) context.push(route);
    }
  }

  /// Yetki-kapılı rota açma. İzin yoksa rota AÇILMAZ; ölü buton yerine dürüst,
  /// hafif geri bildirim gösterilir (sessiz no-op veya boş kırık sayfa yok).
  /// İzin verildiyse true döner.
  static bool openGuardedRoute(
    BuildContext context, {
    required String route,
    required bool allowed,
    String? deniedMessage,
  }) {
    if (!allowed) {
      showAccessDenied(context, deniedMessage);
      return false;
    }
    context.push(route);
    return true;
  }

  /// Ana kabuğa dön (kabuk-içi Günüm/Komuta Merkezi sekmesi varsa onu kullanır).
  static void goHome(BuildContext context) => navigateToAppHome(context);

  /// Erişilemeyen alan için dürüst, hafif geri bildirim.
  static void showAccessDenied(BuildContext context, [String? message]) {
    AppFeedback.lightImpact();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message ?? AppLocalizations.of(context).t('access_denied_area'),
          ),
        ),
      );
  }
}
