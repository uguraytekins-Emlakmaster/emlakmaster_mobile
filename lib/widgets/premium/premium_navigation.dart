import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/shared/widgets/premium_nav_glyph.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kabuk içi Günüm / Komuta Merkezi veya [AppRouter.routeHome].
void navigateToAppHome(BuildContext context) {
  AppFeedback.lightImpact();
  if (ConsultantShellNav.maybeOf(context) != null) {
    ConsultantShellNav.goToHomeTab(context);
    return;
  }
  if (AdminShellNav.maybeOf(context) != null) {
    AdminShellNav.goToHomeTab(context);
    return;
  }
  if (context.mounted) {
    context.go(AppRouter.routeHome);
  }
}

/// Ana sayfaya — sade, keskin altın ikon (paylaşılan nav görsel dili).
class PremiumHomeButton extends StatelessWidget {
  const PremiumHomeButton({super.key, this.compact = false});

  /// Yalnızca görsel ipucu; ana boyut 44pt dokunma hedefini korur.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PremiumNavGlyphButton(
      icon: Icons.home_rounded,
      iconSize: compact ? 19 : 20,
      tooltip: 'Ana sayfa',
      onPressed: () => navigateToAppHome(context),
    );
  }
}

/// Geri/ana sayfa görünürlük modu (kabuk kökü vs. tam sayfa).
enum PremiumNavLeadingMode {
  /// Yığın var: geri (+ isteğe bağlı ana sayfa).
  backAndHome,

  /// Yığın yok ama kabuk dışı tam sayfa: en az ana sayfa kısayolu.
  homeOnly,

  /// Kabuk kök sekmesi: alt gezinme zaten ana sekmeyi sağlar — krom gösterme.
  none,
}

/// Bağlam içinde uygulanacak leading modu.
///
/// Öncelik: yığın varsa geri+home. Yoksa, kabuk kökündeysek (Danışman/Yönetici
/// kabuğu) hiçbir şey (kullanıcı zaten ana sekmede, alt nav var); kabuk dışı
/// tam sayfa veya derin link ise ana sayfa kısayolu — kullanıcı asla mahsur kalmaz.
PremiumNavLeadingMode resolvePremiumNavLeadingMode(BuildContext context) {
  if (AppBackDispatcher.canPopRoute(context)) {
    return PremiumNavLeadingMode.backAndHome;
  }
  final inShellRoot = ConsultantShellNav.maybeOf(context) != null ||
      AdminShellNav.maybeOf(context) != null;
  if (inShellRoot) return PremiumNavLeadingMode.none;
  return PremiumNavLeadingMode.homeOnly;
}

/// Geri (varsa) + ana sayfa — tüm tam sayfa rotalar için.
///
/// Kabuk kök sekmesinde hiçbir şey çizmez (gereksiz krom yok); push edilen veya
/// derin-link edilen tam sayfada geri/ana sayfa garanti eder.
class PremiumNavLeading extends StatelessWidget {
  const PremiumNavLeading({
    super.key,
    this.showHomeWhenCanPop = true,
  });

  /// Geri varken de ana sayfa kısayolu göster.
  final bool showHomeWhenCanPop;

  @override
  Widget build(BuildContext context) {
    switch (resolvePremiumNavLeadingMode(context)) {
      case PremiumNavLeadingMode.none:
        return const SizedBox.shrink();
      case PremiumNavLeadingMode.homeOnly:
        return const PremiumHomeButton(compact: true);
      case PremiumNavLeadingMode.backAndHome:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBackButton(),
            if (showHomeWhenCanPop) ...[
              const SizedBox(width: 6),
              const PremiumHomeButton(compact: true),
            ],
          ],
        );
    }
  }

  static double leadingWidth(BuildContext context) {
    switch (resolvePremiumNavLeadingMode(context)) {
      case PremiumNavLeadingMode.none:
        return 0;
      case PremiumNavLeadingMode.homeOnly:
        return 56;
      case PremiumNavLeadingMode.backAndHome:
        return 104;
    }
  }
}

/// AppBar olmayan özel başlık satırları için inline leading.
///
/// Kabuk kök sekmesinde sıfır yer kaplar (gereksiz krom yok); push/derin-link
/// tam sayfada geri/ana sayfa + sonda boşluk verir. Aynı yüzey hem sekme hem
/// tam sayfa olarak kullanıldığında kullanıcının mahsur kalmasını önler.
class PremiumHeaderNavLeading extends StatelessWidget {
  const PremiumHeaderNavLeading({
    super.key,
    this.trailingGap = 8,
    this.showHomeWhenCanPop = true,
  });

  final double trailingGap;
  final bool showHomeWhenCanPop;

  @override
  Widget build(BuildContext context) {
    if (resolvePremiumNavLeadingMode(context) == PremiumNavLeadingMode.none) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(right: trailingGap),
      child: PremiumNavLeading(showHomeWhenCanPop: showHomeWhenCanPop),
    );
  }
}

/// Yoğun (marka amblemi + başlık + aksiyon) özel başlıkların ÜSTÜNE konan ince
/// geri/ana sayfa satırı. Başlık satırını yatayda kalabalıklaştırmaz; taşma yok.
///
/// Kabuk kök sekmesinde sıfır yer kaplar; push/derin-link tam sayfada solda
/// geri/ana sayfa + altta boşluk verir. Başlık [Column]'unun ilk çocuğu olarak
/// kullanılmalıdır.
class PremiumHeaderNavBar extends StatelessWidget {
  const PremiumHeaderNavBar({
    super.key,
    this.bottomGap = 6,
    this.showHomeWhenCanPop = true,
  });

  final double bottomGap;
  final bool showHomeWhenCanPop;

  @override
  Widget build(BuildContext context) {
    if (resolvePremiumNavLeadingMode(context) == PremiumNavLeadingMode.none) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PremiumNavLeading(showHomeWhenCanPop: showHomeWhenCanPop),
      ),
    );
  }
}
