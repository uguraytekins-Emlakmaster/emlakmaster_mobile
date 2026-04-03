import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/crm_intelligence_explanations.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detay: sıcaklık + sonraki en iyi aksiyon (tek provider, tek okuma turu).
class CustomerInsightStrip extends ConsumerWidget {
  const CustomerInsightStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(customerInsightProvider(customerId));
    return async.when(
      data: (insight) {
        final e = insight.entity;
        final heatLine = e != null
            ? explainHeatNarrative(e, insight.heat, insight.extras)
            : insight.heat.heatReasonSummary;
        final nbaLine = e != null
            ? explainNextBestNarrative(insight.nextBest, insight.heat)
            : insight.nextBest.reasonTr;
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            color: ext.surfaceElevated,
            border: Border.all(color: _borderFor(ext, insight.heat.heatLevel)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeatOrb(level: insight.heat.heatLevel, score: insight.heat.heatScore, ext: ext),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sıcaklık',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: ext.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${insight.heat.heatScore}/100 · ${heatLevelLabelTr(insight.heat.heatLevel)}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          heatLine,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ext.textTertiary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: ext.background.withValues(alpha: 0.55),
                    border: Border.all(color: ext.accent.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: ext.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Önerilen aksiyon',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: ext.textTertiary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight.nextBest.labelTr,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nbaLine,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ext.textSecondary,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space4),
            child: Text(
              'Sıcaklık özeti yüklenemedi. Aşağıyı kaydırıp tekrar deneyin.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ext.textTertiary,
                    height: 1.35,
                  ),
            ),
          ),
    );
  }

  Color _borderFor(AppThemeExtension ext, CustomerHeatLevel level) {
    switch (level) {
      case CustomerHeatLevel.hot:
        return ext.warning.withValues(alpha: 0.45);
      case CustomerHeatLevel.warm:
        return ext.accent.withValues(alpha: 0.35);
      case CustomerHeatLevel.cool:
        return ext.border.withValues(alpha: 0.6);
      case CustomerHeatLevel.cold:
        return ext.border.withValues(alpha: 0.45);
    }
  }
}

class _HeatOrb extends StatelessWidget {
  const _HeatOrb({
    required this.level,
    required this.score,
    required this.ext,
  });

  final CustomerHeatLevel level;
  final int score;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    final fill = switch (level) {
      CustomerHeatLevel.hot => ext.warning,
      CustomerHeatLevel.warm => ext.accent,
      CustomerHeatLevel.cool => ext.textSecondary,
      CustomerHeatLevel.cold => ext.textTertiary,
    };
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill.withValues(alpha: 0.18),
        border: Border.all(color: fill.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: fill,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
