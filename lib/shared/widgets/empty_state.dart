import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  /// Opsiyonel: özel illüstrasyon widget (örn. Lottie veya büyük ikon).
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    const primaryColor = DesignTokens.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.15),
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: primaryColor.withOpacity(0.8),
                ),
              ),
            const SizedBox(height: DesignTokens.space5),
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
                      color: textColor.withOpacity(0.8),
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.space5),
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
