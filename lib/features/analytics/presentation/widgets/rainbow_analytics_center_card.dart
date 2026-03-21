import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Dashboard giriş kartı — altın vurgulu shimmer.
class RainbowAnalyticsCenterCard extends StatelessWidget {
  const RainbowAnalyticsCenterCard({super.key});

  static const Color _gold = DesignTokens.antiqueGold;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        onTap: () {
          context.push(AppRouter.routeRainbowAnalytics);
        },
        child: Shimmer.fromColors(
          baseColor: _gold.withValues(alpha: 0.12),
          highlightColor: _gold.withValues(alpha: 0.35),
          period: const Duration(milliseconds: 2200),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space5),
            decoration: DesignTokens.dashboardCardDecoration(
              surfaceColor: Colors.white.withValues(alpha: 0.03),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, color: _gold, size: 28),
                ),
                const SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rainbow Analytics Center',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: DesignTokens.fontSizeMd,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yatırım istihbaratı, skor ve PDF rapor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _gold.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
