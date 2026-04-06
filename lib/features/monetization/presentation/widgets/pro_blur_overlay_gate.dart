import 'dart:ui';

import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/upgrade_bottom_sheet.dart';
import 'package:flutter/material.dart';

class ProBlurOverlayGate extends StatelessWidget {
  const ProBlurOverlayGate({
    super.key,
    required this.locked,
    required this.child,
    this.feature = 'revenue_insights',
  });

  final bool locked;
  final Widget child;
  final String feature;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    final ext = AppThemeExtension.of(context);
    return Stack(
      children: [
        IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Opacity(
                opacity: 0.72,
                child: child,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ext.background.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unlock full insights with PRO',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Revenue insights and advanced dashboard intelligence stay lightweight, but full context is unlocked on PRO.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ext.textSecondary,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    FilledButton(
                      onPressed: () => showUpgradeBottomSheet(
                        context,
                        feature: feature,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ext.accent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Upgrade to PRO'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
