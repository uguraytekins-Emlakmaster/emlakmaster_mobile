import 'package:emlakmaster_mobile/core/debug/ui_v2_debug.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Phase 2 — obsidian → navy gradient shell backdrop behind tab content.
class PremiumShellBackdrop extends StatelessWidget {
  const PremiumShellBackdrop({
    super.key,
    required this.child,
    this.debugScreenName,
    this.debugDetail,
  });

  final Widget child;

  /// Debug-only label for [UI_V2_ACTIVE] log + on-screen badge.
  final String? debugScreenName;
  final String? debugDetail;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    final backdrop = DecoratedBox(
      decoration: BoxDecoration(gradient: premium.heroGradient),
      child: child,
    );
    final name = debugScreenName;
    if (name == null || name.isEmpty) return backdrop;
    return UiV2DebugScope(
      screenName: name,
      detail: debugDetail,
      child: backdrop,
    );
  }
}
