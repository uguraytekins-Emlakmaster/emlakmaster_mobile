import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard: "Bugün keşfedilen fırsatlar" – sadece score >= %80 (Signal vs Noise).
class DiscoveryPanel extends ConsumerWidget {
  const DiscoveryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(discoveryItemsProvider);
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
              const Icon(Icons.auto_awesome_rounded, color: DesignTokens.primary, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Bugün keşfedilen fırsatlar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '≥%${(AppConstants.opportunityRadarMinScore * 100).toInt()}',
                style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          async.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Bu eşikte fırsat yok. Detay listesinde daha düşük skorluları görebilirsiniz.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: items.map((e) => _DiscoveryTile(item: e)).toList(),
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

class _DiscoveryTile extends StatelessWidget {
  const _DiscoveryTile({required this.item});
  final DealDiscoveryItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: DesignTokens.primary.withOpacity(0.2),
        child: Text(
          '${(item.score * 100).toInt()}',
          style: const TextStyle(color: DesignTokens.primary, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        item.title ?? 'Fırsat',
        style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11), maxLines: 1)
          : null,
    );
  }
}
