import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard: "Bugün keşfedilen fırsatlar" – neomorphic kart, su benzeri akıcı liste animasyonu.
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
      decoration: DesignTokens.cardNeomorphic(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: DesignTokens.antiqueGold, size: 22),
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
                style: TextStyle(color: DesignTokens.antiqueGold.withOpacity(0.8), fontSize: 11),
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
              return _FluidOpportunitiesList(items: items);
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SkeletonLoader(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(18))),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLoader(height: 13, width: double.infinity, borderRadius: BorderRadius.all(Radius.circular(4))),
                            SizedBox(height: 4),
                            SkeletonLoader(height: 11, width: 100, borderRadius: BorderRadius.all(Radius.circular(4))),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            ),
            error: (e, _) => ErrorState(
              message: 'Fırsatlar yüklenemedi.',
              onRetry: () => ref.invalidate(discoveryItemsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

/// Su benzeri akıcı animasyon: her öğe sırayla slide + fade, hafif gecikme ile.
class _FluidOpportunitiesList extends StatefulWidget {
  const _FluidOpportunitiesList({required this.items});
  final List<DealDiscoveryItem> items;

  @override
  State<_FluidOpportunitiesList> createState() => _FluidOpportunitiesListState();
}

class _FluidOpportunitiesListState extends State<_FluidOpportunitiesList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppLifecyclePowerService.shouldReduceMotion;
    return Column(
      children: [
        for (var i = 0; i < widget.items.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${widget.items[i].title}_$i'),
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion ? DesignTokens.durationFast : (DesignTokens.durationNormal + Duration(milliseconds: 80 * (i + 1))),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final opacity = reduceMotion ? 1.0 : value;
              final dy = reduceMotion ? 0.0 : 12 * (1 - value);
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                ),
              );
            },
            child: _DiscoveryTile(item: widget.items[i]),
          ),
      ],
    );
  }
}

class _DiscoveryTile extends StatelessWidget {
  const _DiscoveryTile({required this.item});
  final DealDiscoveryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: DesignTokens.antiqueGold.withOpacity(0.2),
          child: Text(
            '${(item.score * 100).toInt()}',
            style: const TextStyle(color: DesignTokens.antiqueGold, fontSize: 11, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}
