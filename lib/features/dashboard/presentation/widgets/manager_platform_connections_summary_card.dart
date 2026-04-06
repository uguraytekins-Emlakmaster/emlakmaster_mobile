import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_ui_state.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Yönetici dashboard (lean): ofis platform bağlantıları özeti — Ayarlar’daki hub’a kısayol.
/// Danışmanlarda [SizedBox.shrink] (RBAC).
class ManagerPlatformConnectionsSummaryCard extends ConsumerWidget {
  const ManagerPlatformConnectionsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);
    if (!canManage) return const SizedBox.shrink();

    final extEnabled = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyFeatureExternalIntegrations] ?? true,
      ),
    );
    if (!extEnabled) return const SizedBox.shrink();

    final platforms = ref.watch(platformListProvider);
    if (platforms.isEmpty) return const SizedBox.shrink();

    final ext = AppThemeExtension.of(context);
    final total = platforms.length;
    var liveOk = 0;
    var attention = 0;
    DateTime? latestSync;
    for (final p in platforms) {
      if (p.truthKind == PlatformConnectionTruthKind.liveConnected) {
        liveOk++;
      }
      final needsAttention = p.setupLifecycle != null
          ? p.setupLifecycle!.countsAsAttentionForDashboard
          : (p.truthKind == PlatformConnectionTruthKind.setupIncomplete ||
              p.connectionState == PlatformConnectionUiState.needsAttention);
      if (needsAttention) {
        attention++;
      }
      final t = p.lastSyncAt;
      if (t != null && (latestSync == null || t.isAfter(latestSync))) {
        latestSync = t;
      }
    }

    final connectionLine = liveOk > 0
        ? 'Canlı bağlantı: $liveOk/$total'
        : 'Canlı platform bağlantısı henüz aktif değil';
    final String healthLine;
    final Color healthColor;
    if (attention > 0) {
      healthLine = 'Kurulum veya inceleme gerekebilir (canlı senkron kapalı olabilir)';
      healthColor = ext.warning;
    } else if (liveOk == 0) {
      healthLine = 'Kurulum veya doğrulama gerekebilir; bağlantıları Ayarlar’dan yönetin';
      healthColor = ext.textSecondary;
    } else {
      healthLine = 'Canlı entegrasyonlar aktif görünüyor';
      healthColor = ext.accent.withValues(alpha: 0.9);
    }

    final syncHint = latestSync != null
        ? 'Son senkron: ${DateFormat('d MMM HH:mm', 'tr_TR').format(latestSync)}'
        : 'Son senkron: — (demo modunda örnek tarih yok)';

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space4),
        child: Material(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRouter.routeConnectedAccounts);
            },
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.space4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
                border: Border.all(color: ext.border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.hub_outlined, size: 20, color: ext.accent),
                      const SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platform bağlantıları',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.15,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ofis ilan entegrasyonu',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: ext.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push(AppRouter.routeConnectedAccounts);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: ext.accent,
                        ),
                        child: const Text('Yönet'),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    connectionLine,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 16,
                        color: healthColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          healthLine,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: healthColor,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    syncHint,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'İçe aktarma ve geçmiş: Ayarlar → İlanlar ve platform bağlantıları',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary.withValues(alpha: 0.9),
                          fontSize: 11,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
