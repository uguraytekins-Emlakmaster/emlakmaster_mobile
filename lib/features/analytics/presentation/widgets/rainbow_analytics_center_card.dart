import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/analytics/presentation/providers/investment_opportunity_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Dashboard giriş kartı — altın vurgulu shimmer + kişiselleştirilmiş Fırsat Endeksi.
class RainbowAnalyticsCenterCard extends ConsumerWidget {
  const RainbowAnalyticsCenterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final pulseLine = ref.watch(
      investmentOpportunitySummaryProvider.select(
        (async) => async.when(
          data: (s) =>
              'Bugün ${s.regionLabel} için yatırım iştahı: ${s.appetiteLabel}',
          loading: () => 'Piyasa nabzı hesaplanıyor…',
          error: (_, __) {
            final s = InvestmentOpportunitySummary.fallback();
            return 'Bugün ${s.regionLabel} için yatırım iştahı: ${s.appetiteLabel}';
          },
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.uiSurfaceRadius),
        onTap: () {
          context.push(AppRouter.routeRainbowAnalytics);
        },
        child: RepaintBoundary(
          child: Shimmer.fromColors(
            baseColor: ext.accent.withValues(alpha: 0.12),
            highlightColor: ext.accent.withValues(alpha: 0.35),
            period: const Duration(milliseconds: 2200),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.space5),
              decoration: ext.surfaceCardDecoration(
                surfaceColor: Color.alphaBlend(
                  ext.foreground.withValues(alpha: 0.04),
                  ext.surface,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ext.accent.withValues(alpha: 0.45)),
                    ),
                    child: Icon(Icons.auto_graph_rounded, color: ext.accent, size: 28),
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rainbow Analytics Center',
                          style: TextStyle(
                            color: ext.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: DesignTokens.fontSizeMd,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pulseLine,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: DesignTokens.fontSizeSm,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: ext.accent.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
