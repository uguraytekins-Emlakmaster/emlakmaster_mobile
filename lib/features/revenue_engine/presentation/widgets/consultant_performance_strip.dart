import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/data/customer_revenue_signals_builder.dart';
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
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final score = ref.watch(advisorPerformanceScoreProvider);
    final calls = ref.watch(consultantCallsStreamProvider).valueOrNull ?? [];
    final tasksMeta = ref.watch(advisorTasksMetaProvider).valueOrNull;
    final rollup = buildRollupForAdvisor(
      advisorId: uid,
      callDocs: calls,
      missedFollowUps: tasksMeta?.overdueCount ?? 0,
      inactivityDays: 0,
    );
    final explain = _explainTr(rollup);

    if (rollup.callsMade == 0 && score == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'puan',
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: DesignTokens.fontSizeSm,
                        fontWeight: FontWeight.w500,
                      ),
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
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeXs,
                    height: 1.3,
                  ),
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
