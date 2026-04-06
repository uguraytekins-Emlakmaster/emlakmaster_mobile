import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/pro_blur_overlay_gate.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_ui_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri detay: gelir motoru özeti (aksiyon odaklı, tek blok).
class CustomerRevenueIntelligenceStrip extends ConsumerWidget {
  const CustomerRevenueIntelligenceStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final blurLocked = ref.watch(shouldBlurRevenueInsightsProvider);
    final signal = ref.watch(
      customerRevenueSignalsMapProvider.select((m) => m[customerId]),
    );
    if (signal == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space3),
        child: Text(
          'Gelir skoru, atanmış müşteri listeniz ve çağrı kayıtlarıyla hesaplanır.',
          style: TextStyle(
              color: ext.textTertiary, fontSize: DesignTokens.fontSizeXs),
        ),
      );
    }

    final band = revenueBandLabelTr(signal.band);
    final nextLine = signal.recommendationSuppressed
        ? (signal.suppressionReason ?? 'Öneri şimdilik gösterilmiyor.')
        : revenueNextActionLine(signal);
    final why = revenueValueExplanationShort(signal);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: ProBlurOverlayGate(
        locked: blurLocked,
        child: Container(
          padding: AppTypography.cardPadding,
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: ext.accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_outlined, size: 18, color: ext.accent),
                  const SizedBox(width: DesignTokens.space2),
                  Text(
                    'Gelir zekâsı',
                    style: AppTypography.cardHeading(context),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space4),
              _kv(context, 'Lead skoru', '${signal.leadScore}'),
              const SizedBox(height: DesignTokens.space2),
              _kv(context, 'Sıcaklık', band),
              const SizedBox(height: DesignTokens.space2),
              _kv(context, 'Önerilen aksiyon', nextLine),
              const SizedBox(height: DesignTokens.space3),
              Text(
                why,
                style: AppTypography.body(context),
              ),
              if (signal.syncDelayedRisk) ...[
                const SizedBox(height: DesignTokens.space2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 16, color: ext.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Senkron riski: yerel çağrı kaydı henüz tam yansımamış olabilir.',
                        style: TextStyle(
                            color: ext.warning,
                            fontSize: DesignTokens.fontSizeXs),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _kv(BuildContext context, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(
            k,
            style: AppTypography.meta(context),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: AppTypography.bodyStrong(context),
          ),
        ),
      ],
    );
  }
}
