import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium docked CTA — sits **above** the bottom navigation, never over scroll content.
///
/// İki ayrı yol: varsayılan **gerçek telefon** (sistem `tel:`), ikincil **Magic Call CRM**.
class MagicCallDockedBar extends StatelessWidget {
  const MagicCallDockedBar({
    super.key,
    required this.onPhonePressed,
    required this.onMagicCrmPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Sistem telefonu / numara girişi (varsayılan).
  final VoidCallback onPhonePressed;

  /// Uygulama içi CRM oturumu (Magic Call).
  final VoidCallback onMagicCrmPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Visual height of the bar (excluding outer borders).
  static const double barHeight = 56;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Telefon ile ara',
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onPhonePressed();
                      },
                      icon: Icon(Icons.call_rounded, size: 18, color: fg),
                      label: const Text('Telefon'),
                      style: FilledButton.styleFrom(
                        backgroundColor: bg,
                        foregroundColor: fg,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Magic Call CRM oturumu',
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onMagicCrmPressed();
                      },
                      icon: Icon(Icons.phone_in_talk_rounded, size: 18, color: ext.textPrimary),
                      label: const Text('Magic CRM'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ext.textPrimary,
                        side: BorderSide(color: ext.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                    ),
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
