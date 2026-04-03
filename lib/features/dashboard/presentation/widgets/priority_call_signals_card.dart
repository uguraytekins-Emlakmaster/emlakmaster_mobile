import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/crm_intelligence_explanations.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_next_best_action.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman: atanmış müşteriler. Broker/yönetici: ofis üyelerinin müşterileri (üyelik + `assignedAgentId`).
class PriorityCallSignalsCard extends ConsumerWidget {
  const PriorityCallSignalsCard({super.key});

  static const int _maxRowsConsultant = 5;
  static const int _maxRowsOffice = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final useOfficeWide = role.isManagerTier;
    final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    final officeId =
        uid.isEmpty ? '' : (ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '');

    final AsyncValue<List<CustomerEntity>> async = useOfficeWide && officeId.isNotEmpty
        ? ref.watch(officeWideCustomerListProvider(officeId))
        : ref.watch(customerListForAgentProvider);

    final maxRows =
        useOfficeWide && officeId.isNotEmpty ? _maxRowsOffice : _maxRowsConsultant;
    final subtitle = useOfficeWide && officeId.isNotEmpty
        ? 'Ofis geneli — yüksek ilgi, acil takip, randevu veya fiyat itirazı'
        : 'Yüksek ilgi, acil takip, randevu veya fiyat itirazı';

    return async.when(
      data: (customers) {
        final ranked = customers
            .where((c) =>
                c.lastCallSummarySignals != null &&
                postCallSignalsIsPriority(c.lastCallSummarySignals!))
            .toList()
          ..sort((a, b) {
            final sa = postCallSignalsPriorityScore(a.lastCallSummarySignals!);
            final sb = postCallSignalsPriorityScore(b.lastCallSummarySignals!);
            return sb.compareTo(sa);
          });
        final top = ranked.take(maxRows).toList();
        if (top.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(color: ext.border.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.priority_high_rounded, size: 20, color: ext.warning),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        'Öncelikli takip (çağrı sinyalleri)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: DesignTokens.space3),
                ...top.map((c) => _PriorityRow(
                      customer: c,
                      onTap: () => context.push('/customer/${c.id}'),
                    )),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.customer,
    required this.onTap,
  });

  final CustomerEntity customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final heat = computeCustomerHeat(customer);
    final nextBest = computeNextBestActionForList(customer);
    final nbaExplain = explainNextBestNarrative(nextBest, heat);
    final aiSnippet = savedAiInsightSnippetTr(customer.lastCallAiEnrichment);
    final s = customer.lastCallSummarySignals!;
    final badges = <Widget>[];
    if (s.interestLevel == PostCallCrmSignals.interestHigh) {
      badges.add(_rowBadge('İlgi', ext.accent, ext));
    }
    if (s.followUpUrgency == PostCallCrmSignals.urgencyHigh) {
      badges.add(_rowBadge('Acil', ext.warning, ext));
    }
    if (s.appointmentMentioned) {
      badges.add(_rowBadge('Randevu', ext.success, ext));
    }
    if (s.priceObjection) {
      badges.add(_rowBadge('Fiyat', ext.warning, ext));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName ?? 'Müşteri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Öneri: ${nextBest.labelTr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                      ),
                      const SizedBox(height: 2),
                      if (aiSnippet != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 13,
                                color: ext.accent.withValues(alpha: 0.88),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                aiSnippet,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ext.textSecondary,
                                      height: 1.25,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          nbaExplain,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ext.textTertiary,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _HeatMiniPill(heat: heat, ext: ext),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: badges,
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right_rounded, color: ext.textTertiary, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _HeatMiniPill extends StatelessWidget {
  const _HeatMiniPill({required this.heat, required this.ext});

  final CustomerHeatSnapshot heat;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    final c = switch (heat.heatLevel) {
      CustomerHeatLevel.hot => ext.warning,
      CustomerHeatLevel.warm => ext.accent,
      CustomerHeatLevel.cool => ext.textSecondary,
      CustomerHeatLevel.cold => ext.textTertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${heat.heatScore} · ${heatLevelLabelTr(heat.heatLevel)}',
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Widget _rowBadge(String label, Color color, AppThemeExtension ext) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: color.withValues(alpha: 0.14),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
