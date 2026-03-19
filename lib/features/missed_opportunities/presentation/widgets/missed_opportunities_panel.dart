import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard: "Missed Opportunities" – kaçırılmış fırsatlar.
class MissedOpportunitiesPanel extends ConsumerWidget {
  const MissedOpportunitiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewWarRoom(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(missedOpportunitiesProvider);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.money_off_rounded, color: DesignTokens.danger, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Kaçırılan fırsatlar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
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
                    'Kaçırılmış fırsat tespiti yok.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: items.map((e) => _MissedTile(item: e)).toList(),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SkeletonLoader(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                      SizedBox(width: 12),
                      Expanded(
                        child: SkeletonLoader(height: 12, width: double.infinity, borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                    ],
                  ),
                )),
              ),
            ),
            error: (e, _) => ErrorState(
              message: 'Kaçırılan fırsatlar yüklenemedi.',
              onRetry: () => ref.invalidate(missedOpportunitiesProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedTile extends StatelessWidget {
  const _MissedTile({required this.item});
  final MissedOpportunityItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: DesignTokens.danger.withOpacity(0.2),
        child: Text(
          '${(item.score * 100).toInt()}',
          style: const TextStyle(color: DesignTokens.danger, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        item.reason ?? 'Fırsat',
        style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
