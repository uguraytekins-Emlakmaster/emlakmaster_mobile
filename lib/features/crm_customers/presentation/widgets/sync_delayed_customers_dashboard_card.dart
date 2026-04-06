import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Özetim: yerel çağrı verisi senkronu gecikmiş müşteri sayısı.
class SyncDelayedCustomersDashboardCard extends ConsumerWidget {
  const SyncDelayedCustomersDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(syncDelayedRiskCustomerIdsProvider);
    final n = ids.length;
    if (n == 0) return const SizedBox.shrink();

    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
      child: InkWell(
        onTap: () => ConsultantShellNav.goToCustomersTab(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_queue_rounded,
                size: 22,
                color: ext.warning.withValues(alpha: 0.85),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verisi geciken müşteriler',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$n müşteri · Veri senkronu gecikmiş olabilir',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ext.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ext.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
