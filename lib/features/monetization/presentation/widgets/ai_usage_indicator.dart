import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiUsageIndicator extends ConsumerWidget {
  const AiUsageIndicator({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageTrackerProvider);
    final ext = AppThemeExtension.of(context);
    final label = compact
        ? usage.isPro
            ? 'AI: ${usage.aiUsageThisMonth} kullanım · PRO sınırsız'
            : 'AI: ${usage.aiUsageThisMonth} / 20 bu ay'
        : usage.isPro
            ? 'Bu ay ${usage.aiUsageThisMonth} AI önerisi kullandın · PRO sınırsız'
            : 'Bu ay ${usage.aiUsageThisMonth} / 20 AI hakkı kullandın';
    final tone = usage.isFree && usage.isNearAiLimit ? ext.warning : ext.info;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DesignTokens.space3 : DesignTokens.space4,
        vertical: compact ? DesignTokens.space2 : DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: compact ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border:
            Border.all(color: tone.withValues(alpha: compact ? 0.18 : 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 16, color: tone),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
