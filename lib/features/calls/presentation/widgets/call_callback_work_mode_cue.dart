import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// “Geri aranacaklar” filtresi açıkken hafif öncelik iş yüzeyi ipucu.
class CallCallbackWorkModeCue extends StatelessWidget {
  const CallCallbackWorkModeCue({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        DesignTokens.space2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.accent.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: ext.accent.withValues(alpha: 0.20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: ext.accent.withValues(alpha: 0.88),
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Text(
                  'Geri aranacaklar — $count kayıt · öncelik kuyruğu',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
