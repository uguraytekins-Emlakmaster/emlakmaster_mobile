import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_motion_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

enum PremiumButtonVariant { primary, secondary, ghost, destructive }

enum PremiumButtonSize { sm, md, lg }

/// Phase 1 — gold pill primary; glass secondary; executive spacing.
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PremiumButtonVariant.primary,
    this.size = PremiumButtonSize.md,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PremiumButtonVariant variant;
  final PremiumButtonSize size;
  final bool expanded;
  final bool loading;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  double get _height => switch (widget.size) {
        PremiumButtonSize.sm => 40,
        PremiumButtonSize.md => 48,
        PremiumButtonSize.lg => 52,
      };

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final enabled = widget.onPressed != null && !widget.loading;

    final child = AnimatedScale(
      scale: _pressed ? PremiumMotionTokens.pressScale : 1,
      duration: PremiumMotionTokens.instant,
      curve: PremiumMotionTokens.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  AppFeedback.lightImpact();
                  widget.onPressed?.call();
                }
              : null,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          child: Ink(
            height: _height,
            decoration: _decoration(ext, premium),
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == PremiumButtonSize.sm
                  ? DesignTokens.space4
                  : DesignTokens.space5,
            ),
            child: Row(
              mainAxisSize:
                  widget.expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _foreground(ext, premium),
                    ),
                  )
                else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: _foreground(ext, premium)),
                  const SizedBox(width: DesignTokens.space2),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _foreground(ext, premium),
                    fontWeight: FontWeight.w700,
                    fontSize: widget.size == PremiumButtonSize.sm
                        ? DesignTokens.fontSizeSm
                        : DesignTokens.fontSizeBase,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }

  BoxDecoration _decoration(AppThemeExtension ext, PremiumThemeExtension premium) {
    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          gradient: PremiumGlassTokens.goldAccentGradient(),
          boxShadow: enabled ? PremiumShadowTokens.goldGlow() : null,
        );
      case PremiumButtonVariant.secondary:
        return PremiumGlassTokens.surface(
          isDark: premium.isDark,
          radius: DesignTokens.radiusFull,
          goldBorder: true,
        );
      case PremiumButtonVariant.ghost:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(color: ext.border.withValues(alpha: 0.55)),
        );
      case PremiumButtonVariant.destructive:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          color: ext.danger.withValues(alpha: 0.16),
          border: Border.all(color: ext.danger.withValues(alpha: 0.45)),
        );
    }
  }

  Color _foreground(AppThemeExtension ext, PremiumThemeExtension premium) {
    if (!enabled) return ext.textTertiary;
    return switch (widget.variant) {
      PremiumButtonVariant.primary => ext.onBrand,
      PremiumButtonVariant.destructive => ext.danger,
      _ => premium.isDark ? ext.textPrimary : ext.textPrimary,
    };
  }

  bool get enabled => widget.onPressed != null && !widget.loading;
}
