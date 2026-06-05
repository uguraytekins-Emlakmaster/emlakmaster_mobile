import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Geri / ana sayfa için tek görsel dil: keskin, sade, lüks.
///
/// 44pt dokunma hedefi (dış [tapSize]); içte daha küçük, ince çerçeveli krom.
/// Light/dark tema [AppThemeExtension] üzerinden; altın vurgu yalnızca ikon ve
/// hairline kenarda (parıltı/gölge spam yok). Haptic'i çağıran taraf yönetir.
class PremiumNavGlyphButton extends StatelessWidget {
  const PremiumNavGlyphButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 18,
    this.visualSize = 40,
    this.tapSize = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;
  final double visualSize;
  final double tapSize;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final radius = BorderRadius.circular(DesignTokens.radiusMd);
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: tapSize,
          height: tapSize,
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Container(
                  width: visualSize,
                  height: visualSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ext.accent.withValues(alpha: 0.08),
                    borderRadius: radius,
                    border: Border.all(
                      color: ext.accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, size: iconSize, color: ext.accent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
