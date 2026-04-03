import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/broker_customer_alert.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/crm_intelligence_explanations.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_alerts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Broker / yönetici dashboard üst bölümü: kritik müşteri uyarıları.
class BrokerDashboardAlertsCard extends ConsumerWidget {
  const BrokerDashboardAlertsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(brokerDashboardAlertsProvider);
    return async.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(color: ext.danger.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 20, color: ext.danger),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        'Operasyon uyarıları',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ext.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Sıcaklık, çağrı sinyalleri ve temas zamanlamasına göre',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: DesignTokens.space3),
                ...items.map((a) => _AlertRow(item: a)),
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

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.item});

  final BrokerCustomerAlertItem item;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final pColor = switch (item.priorityLevel) {
      BrokerAlertPriority.high => ext.danger,
      BrokerAlertPriority.medium => ext.warning,
      BrokerAlertPriority.low => ext.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/customer/${item.customerId}'),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: pColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.customerName?.trim().isNotEmpty == true
                                  ? item.customerName!.trim()
                                  : 'Müşteri',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: pColor.withValues(alpha: 0.12),
                              border: Border.all(color: pColor.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              _priorityLabel(item.priorityLevel),
                              style: TextStyle(
                                color: pColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explainBrokerAlertTitleTr(item.code),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (item.aiInsightLineTr != null &&
                          item.aiInsightLineTr!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: ext.accent.withValues(alpha: 0.88),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.aiInsightLineTr!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: ext.textSecondary,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        explainBrokerAlertDescriptionTr(item.code),
                        maxLines: item.aiInsightLineTr != null &&
                                item.aiInsightLineTr!.trim().isNotEmpty
                            ? 1
                            : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.textTertiary,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: ext.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(BrokerAlertPriority p) {
    switch (p) {
      case BrokerAlertPriority.high:
        return 'YÜKSEK';
      case BrokerAlertPriority.medium:
        return 'ORTA';
      case BrokerAlertPriority.low:
        return 'DÜŞÜK';
    }
  }
}
