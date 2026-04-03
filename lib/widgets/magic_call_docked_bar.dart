import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium docked CTA — sits **above** the bottom navigation, never over scroll content.
///
/// Replaces the floating [MagicCallWizardFab] on shells where the call entry must not
/// obscure lists or cards.
class MagicCallDockedBar extends StatelessWidget {
  const MagicCallDockedBar({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Visual height of the bar (excluding outer borders).
  static const double barHeight = 52;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bg = backgroundColor ?? ext.brandPrimary;
    final fg = foregroundColor ?? ext.onBrand;

    return Material(
      color: ext.surfaceElevated,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: ext.shadowColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: barHeight,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onPressed();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bg.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                        color: fg.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(Icons.phone_in_talk_rounded, color: fg, size: 22),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Magic Call',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                        ),
                        Text(
                          'AI özeti ve CRM akışı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ext.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: ext.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
