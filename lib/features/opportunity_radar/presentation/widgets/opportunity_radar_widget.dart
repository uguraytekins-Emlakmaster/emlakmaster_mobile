import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

/// Opportunity Radar: bugünün en sıcak lead'leri, at-risk deal'ler, gecikmiş follow-up, yeniden aktif lead'ler.
class OpportunityRadarWidget extends ConsumerWidget {
  const OpportunityRadarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider);
    if (role == null || !FeaturePermission.canViewOpportunityRadar(role)) {
      return const SizedBox.shrink();
    }
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
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
              const Icon(Icons.radar_rounded, color: DesignTokens.primary, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Fırsat radarı',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRouter.routeWarRoom),
                child: const Text('War Room', style: TextStyle(color: DesignTokens.primary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          resurrectionAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Şu an öne çıkan fırsat yok.',
                    style: TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 13),
                  ),
                );
              }
              return Column(
                children: items.take(3).map((e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.replay_rounded, size: 18, color: DesignTokens.warning),
                  title: Text(
                    e.customerName ?? e.customerId,
                    style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${e.daysSilent} gün sessiz', style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 11)),
                  onTap: () {},
                )).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary)),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Yüklenemedi.', style: TextStyle(color: DesignTokens.danger, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
