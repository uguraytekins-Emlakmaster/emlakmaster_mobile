import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/pro_blur_overlay_gate.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Broker / yönetici dashboard: operasyonel gelir özeti (hafif).
class ManagerRevenueSummaryCard extends ConsumerWidget {
  const ManagerRevenueSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    if (!role.isManagerTier) {
      return const SizedBox.shrink();
    }

    final snap = ref.watch(brokerRevenueDashboardSnapshotProvider);
    final blurLocked = ref.watch(shouldBlurRevenueInsightsProvider);
    final ext = AppThemeExtension.of(context);

    final hasHot = snap.hotCustomers.isNotEmpty;
    final hasToday = snap.actionToday.isNotEmpty;
    final hasRisk = snap.atRiskSync.isNotEmpty;
    final hasBoard = snap.leaderboard.isNotEmpty;

    final syncSummary = hasRisk
        ? '${snap.atRiskSync.length} müşteride senkron / veri riski'
        : 'Senkron riski görünmüyor';
    final anySignals = hasHot || hasToday || hasRisk || hasBoard;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: ProBlurOverlayGate(
        locked: blurLocked,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gelir özeti',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (anySignals) ...[
              _Row(
                icon: Icons.local_fire_department_outlined,
                iconColor: ext.warning,
                title: 'Sıcak müşteriler',
                subtitle: hasHot
                    ? snap.hotCustomers
                        .map((e) => e.displayName)
                        .take(3)
                        .join(', ')
                    : 'Şu an sıcak bandında kayıt yok',
                count: snap.hotCustomers.length,
                onTap: () => _openFirstCustomer(context, snap.hotCustomers),
              ),
              const SizedBox(height: 6),
              _Row(
                icon: Icons.bolt_rounded,
                iconColor: ext.success,
                title: 'En aktif danışmanlar',
                subtitle: hasBoard
                    ? snap.leaderboard
                        .take(3)
                        .map((e) =>
                            '#${e.rank ?? '-'} ${e.displayLabel} (${e.performanceScore})')
                        .join(' · ')
                    : 'Çağrı verisi yetersiz',
              ),
              const SizedBox(height: 6),
              _Row(
                icon: Icons.warning_amber_rounded,
                iconColor: ext.danger,
                title: 'Risk / senkron',
                subtitle: hasRisk
                    ? snap.atRiskSync
                        .map((e) => e.displayName)
                        .take(3)
                        .join(', ')
                    : 'Öncelikli risk satırı yok',
                count: snap.atRiskSync.length,
                onTap: () => _openFirstCustomer(context, snap.atRiskSync),
              ),
              const SizedBox(height: 6),
            ],
            _Row(
              icon: Icons.cloud_sync_outlined,
              iconColor: ext.textSecondary,
              title: 'Senkron özeti',
              subtitle: syncSummary,
            ),
            if (!anySignals) ...[
              const SizedBox(height: 6),
              Text(
                'Ofis müşteri ve çağrı kayıtları geldikçe sıcak müşteri ve danışman sıralaması dolar.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ext.textTertiary, height: 1.3),
              ),
            ],
            if (hasToday) ...[
              const SizedBox(height: 6),
              _Row(
                icon: Icons.today_outlined,
                iconColor: ext.accent,
                title: 'Bugün aksiyon',
                subtitle: snap.actionToday
                    .map((e) => e.displayName)
                    .take(3)
                    .join(', '),
                count: snap.actionToday.length,
                onTap: () => _openFirstCustomer(context, snap.actionToday),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _openFirstCustomer(
      BuildContext context, List<CustomerRevenueRow> rows) {
    if (rows.isEmpty) return;
    final id = rows.first.customerId;
    if (id.isEmpty) return;
    context.push(AppRouter.routeCustomerDetail.replaceFirst(':id', id));
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.count,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (count != null && count! > 0)
                      Text(
                        '$count',
                        style: TextStyle(
                          color: ext.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ext.textTertiary,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                color: ext.textTertiary, size: 20),
        ],
      ),
    );

    return Material(
      color: ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              borderRadius:
                  BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
              child: body,
            ),
    );
  }
}
