import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman paneli: performans skoru + kısa gerekçe (liste kartı hissi).
class ConsultantPerformanceStrip extends ConsumerWidget {
  const ConsultantPerformanceStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final score = ref.watch(advisorPerformanceScoreProvider);
    final rollup = ref.watch(advisorPerformanceRollupProvider);
    final explain = _explainTr(rollup);
    final radius =
        BorderRadius.circular(DashboardLayoutTokens.radiusCardM);

    if (rollup.callsMade == 0 && score == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space5,
          vertical: DesignTokens.space4,
        ),
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: radius,
          border: Border.all(color: ext.border.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: ext.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                    DashboardLayoutTokens.radiusCardS),
              ),
              child: Icon(Icons.trending_up_rounded,
                  color: ext.accent, size: 22),
            ),
            const SizedBox(width: DesignTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skorun şekilleniyor',
                    style: AppTypography.cardHeading(context),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'İlk kayıtlı çağrından itibaren puanın ve sıralaman burada güçlenir. '
                    'Her ulaşım, randevu ve teklif seni ileri taşır.',
                    style: AppTypography.body(context).copyWith(
                      color: ext.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space5,
        vertical: DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: radius,
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: ext.accent, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  'Bugünkü momentum',
                  style: AppTypography.metricLabel(context).copyWith(
                    color: ext.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space1 + 1,
                ),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                      DashboardLayoutTokens.radiusCardS),
                ),
                child: Text(
                  'Sıra: —',
                  style: TextStyle(
                    color: ext.accent,
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: AppTypography.metricValue(context).copyWith(
                  fontSize: 36,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'puan',
                  style: AppTypography.metricLabel(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            explain,
            style: AppTypography.body(context).copyWith(height: 1.45),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static String _explainTr(ConsultantActivityRollup r) {
    if (r.callsMade == 0) {
      return 'Kayıtlı çağrı arttıkça puanınız oluşur (ulaşım, randevu, teklif ağırlıklı).';
    }
    return '${r.callsMade} çağrı · ${r.successfulCalls} ulaşım · ${r.appointmentsCreated} randevu · '
        '${r.offersRecorded} teklif · geciken görev: ${r.missedFollowUps}';
  }
}
