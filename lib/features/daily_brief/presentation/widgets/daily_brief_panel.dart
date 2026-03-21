import 'package:emlakmaster_mobile/core/intelligence/intelligence_providers.dart';
import 'package:emlakmaster_mobile/core/intelligence/intelligence_score_models.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard: "AI Daily Brief" – bugünün kritik bilgileri.
class DailyBriefPanel extends ConsumerWidget {
  const DailyBriefPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewWarRoom(role)) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(dailyBriefProvider);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded, color: DesignTokens.primary, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Bugünün özeti',
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
                    'Özet hazırlanıyor.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: items.map((e) => _BriefTile(item: e)).toList(),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SkeletonLoader(width: 20, height: 20, borderRadius: BorderRadius.all(Radius.circular(4))),
                      SizedBox(width: 12),
                      Expanded(
                        child: SkeletonLoader(height: 13, width: double.infinity, borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                    ],
                  ),
                )),
              ),
            ),
            error: (e, _) => ErrorState(
              message: 'Bugünün özeti yüklenemedi.',
              onRetry: () => ref.invalidate(dailyBriefProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _BriefTile extends StatelessWidget {
  const _BriefTile({required this.item});
  final DailyBriefItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _iconForCategory(item.category),
        size: 20,
        color: DesignTokens.primary.withValues(alpha: 0.9),
      ),
      title: Text(
        item.title ?? '',
        style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11))
          : null,
    );
  }

  static IconData _iconForCategory(String? c) {
    switch (c) {
      case 'high_budget': return Icons.attach_money_rounded;
      case 'region_demand': return Icons.trending_up_rounded;
      case 'closing_soon': return Icons.schedule_rounded;
      case 'silent_leads': return Icons.notifications_off_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}
