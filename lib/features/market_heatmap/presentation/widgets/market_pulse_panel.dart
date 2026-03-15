import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard: "Market Pulse" – Diyarbakır piyasa dinamikleri, bölgesel talep.
class MarketPulsePanel extends ConsumerWidget {
  const MarketPulsePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(marketHeatmapProvider);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: DesignTokens.primary, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Market Pulse',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          async.when(
            data: (regions) {
              if (regions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Bölgesel talep hesaplanıyor.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: regions.map((e) => _RegionRow(region: e)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary),
              ),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Yüklenemedi.', style: TextStyle(color: DesignTokens.danger, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({required this.region});
  final RegionHeatmapScore region;

  @override
  Widget build(BuildContext context) {
    final pct = (region.demandScore * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              region.regionName,
              style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: 13),
            ),
          ),
          if (region.budgetSegment != null)
            Text(
              region.budgetSegment!,
              style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11),
            ),
          const SizedBox(width: 8),
          Text(
            '%$pct',
            style: TextStyle(
              color: region.demandScore >= 0.7 ? DesignTokens.success : DesignTokens.textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
