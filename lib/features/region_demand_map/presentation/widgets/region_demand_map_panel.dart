import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Bölge talep haritası: hangi mahallede talep artıyor, fiyat yükseliyor, satış hızlı.
/// 🔴 çok talep | 🟡 orta | 🟢 normal
class RegionDemandMapPanel extends ConsumerWidget {
  const RegionDemandMapPanel({super.key});

  static String _demandEmoji(double score) {
    if (score >= 0.6) return '🔴';
    if (score >= 0.3) return '🟡';
    return '🟢';
  }

  static String _demandLabel(double score) {
    if (score >= 0.6) return 'Çok talep';
    if (score >= 0.3) return 'Orta';
    return 'Normal';
  }

  static Color _demandColor(AppThemeExtension ext, double score) {
    if (score >= 0.6) return ext.danger;
    if (score >= 0.3) return ext.warning;
    return ext.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(marketHeatmapProvider);
    return async.when(
      data: (regions) {
        if (regions.isEmpty) {
          return const EmptyState(
            icon: Icons.map_rounded,
            title: 'Bölge talep verisi yok',
            subtitle: 'Talep haritası güncellenince burada görünecek.',
          );
        }
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: ext.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.map_rounded, color: ext.accent, size: 20),
                  const SizedBox(width: DesignTokens.space2),
                  Text(
                    'Bölge talep haritası',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space3),
              const Wrap(
                spacing: DesignTokens.space2,
                runSpacing: DesignTokens.space2,
                children: [
                  _LegendChip(emoji: '🔴', label: 'Çok talep'),
                  _LegendChip(emoji: '🟡', label: 'Orta'),
                  _LegendChip(emoji: '🟢', label: 'Normal'),
                ],
              ),
              const SizedBox(height: DesignTokens.space4),
              ...regions.map((r) => _RegionTile(
                    name: r.regionName,
                    demandScore: r.demandScore,
                    budgetSegment: r.budgetSegment,
                    propertyHint: r.propertyTypeHint,
                  )),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(DesignTokens.space6),
        decoration: BoxDecoration(
          color: ext.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: ext.accent),
            ),
            const SizedBox(width: DesignTokens.space4),
            Text('Talep haritası yükleniyor...', style: TextStyle(color: ext.textSecondary)),
          ],
        ),
      ),
      error: (e, st) => ErrorState(
        message: 'Talep haritası yüklenemedi.',
        onRetry: () => ref.invalidate(marketHeatmapProvider),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.background,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: ext.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.name,
    required this.demandScore,
    this.budgetSegment,
    this.propertyHint,
  });
  final String name;
  final double demandScore;
  final String? budgetSegment;
  final String? propertyHint;

  @override
  Widget build(BuildContext context) {
    final emoji = RegionDemandMapPanel._demandEmoji(demandScore);
    final label = RegionDemandMapPanel._demandLabel(demandScore);
    final ext = AppThemeExtension.of(context);
    final color = RegionDemandMapPanel._demandColor(ext, demandScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3, vertical: DesignTokens.space2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                  if (budgetSegment != null || propertyHint != null)
                    Text(
                      [budgetSegment, propertyHint].whereType<String>().join(' • '),
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
