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

    if (rollup.callsMade == 0 && score == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: AppTypography.cardPadding,
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.speed_rounded, color: ext.accent, size: 22),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performansın',
                  style: AppTypography.cardHeading(context)
                      .copyWith(color: ext.textSecondary),
                ),
                const SizedBox(height: DesignTokens.titleSubtitleGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: AppTypography.metricValue(context)
                          .copyWith(fontSize: 28),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'puan',
                      style: AppTypography.metricLabel(context),
                    ),
                    const Spacer(),
                    Text(
                      'Sıra: —',
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: DesignTokens.fontSizeXs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  explain,
                  style: AppTypography.body(context),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
