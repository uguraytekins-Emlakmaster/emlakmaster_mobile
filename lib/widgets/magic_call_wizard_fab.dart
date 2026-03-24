import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Danışman (ve broker) kabuğundaki yüzen "Magic Call & AI Wizard" CTA.
///
/// [scrollBottomPadding] ile Özetim gibi kaydırılabilir sayfalarda içerik,
/// FAB ve alt gezinme arasında çakışmasın diye alt boşluk hesaplanır.
class MagicCallWizardFab extends StatelessWidget {
  const MagicCallWizardFab({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.boxShadow,
  });

  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<BoxShadow>? boxShadow;

  static const double width = 220;
  static const double height = 56;

  /// [floatingActionButton] konumunda alt gezinmenin üstüne çekmek için iç boşluk.
  static const double anchorBottomPadding = 72;

  /// Pill + anchor boşluğu + nefes payı (kaydırma alanı için taban).
  static const double _scrollBand = height + anchorBottomPadding + 16;

  /// Özetim vb. scroll içeriğinin altına eklenecek boşluk (FAB görünürken).
  static double scrollBottomPadding(BuildContext context, {required bool showFab}) {
    if (!showFab) return DesignTokens.space8;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return _scrollBand + safeBottom + DesignTokens.space2;
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bg = backgroundColor ?? ext.accent;
    final fg = foregroundColor ?? ext.onBrand;
    final shadows = boxShadow ??
        [
          BoxShadow(
            color: ext.accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

    return Padding(
      padding: const EdgeInsets.only(bottom: anchorBottomPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(28),
          splashColor: fg.withValues(alpha: 0.12),
          highlightColor: fg.withValues(alpha: 0.06),
          child: Ink(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: bg,
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_in_talk_rounded, color: fg, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Magic Call & AI Wizard',
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
