import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/opportunity_radar/presentation/widgets/opportunity_radar_laboratory_empty.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/resurrection_lead_topic_sheet.dart';
import 'package:emlakmaster_mobile/shared/widgets/error_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      decoration: DesignTokens.dashboardCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: DesignTokens.primary, size: 22),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  'Fırsat radarı',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: DesignTokens.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  ),
                ),
                onPressed: () => context.push(AppRouter.routeWarRoom),
                child: const Text('War Room', style: TextStyle(color: DesignTokens.primary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          resurrectionAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const OpportunityRadarLaboratoryEmpty();
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
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showResurrectionLeadTopicSheet(
                      context,
                      topicTitle: 'Fırsat radarı',
                      item: e,
                    );
                  },
                )).toList(),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SkeletonLoader(width: 18, height: 18, borderRadius: BorderRadius.all(Radius.circular(4))),
                      SizedBox(width: 12),
                      Expanded(
                        child: SkeletonLoader(height: 13, width: double.infinity, borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                    ],
                  ),
                )),
              ),
            ),
            error: (_, __) => ErrorState(
              message: 'Fırsat radarı yüklenemedi.',
              onRetry: () => ref.invalidate(resurrectionQueueProvider),
            ),
          ),
        ],
      ),
    );
  }
}
