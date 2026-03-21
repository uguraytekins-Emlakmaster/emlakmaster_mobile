import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/pressable_scale_button.dart';

/// Boş liste / boş sonuç ekranı. Premium empty state + illüstrasyon alanı.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.outlinedActionLabel,
    this.onOutlinedAction,
    this.compact = false,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  /// Hayalet / ikincil eylem (OutlinedButton).
  final String? outlinedActionLabel;
  final VoidCallback? onOutlinedAction;
  /// Küçük ikon ve daha az dikey boşluk (Çağrı Merkezi, Raporlar).
  final bool compact;
  /// Opsiyonel: özel illüstrasyon widget (örn. Lottie veya büyük ikon).
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final textColor = ext.foregroundSecondary;
    const primaryColor = DesignTokens.primary;

    final iconBox = compact ? 56.0 : 96.0;
    final iconSize = compact ? 28.0 : 48.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? DesignTokens.space4 : DesignTokens.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.12),
                      primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: primaryColor.withValues(alpha: 0.75),
                ),
              ),
            SizedBox(height: compact ? DesignTokens.space3 : DesignTokens.space5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                    ),
              ),
            ],
            if (outlinedActionLabel != null && onOutlinedAction != null) ...[
              SizedBox(height: compact ? DesignTokens.space3 : DesignTokens.space4),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onOutlinedAction!();
                },
                icon: const Icon(Icons.add_rounded, size: 18, color: DesignTokens.primary),
                label: Text(
                  outlinedActionLabel!,
                  style: const TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignTokens.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? DesignTokens.space3 : DesignTokens.space5),
              PressableScaleButton(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onAction!();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
