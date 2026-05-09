import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
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
      healthLine =
          'Bazı kanallarda kurulum veya doğrulama bekleniyor; canlı senkron kapanmış olabilir.';
      healthColor = ext.warning;
    } else if (liveOk == 0) {
      healthLine =
          'Canlı bağlantı henüz yok; ilan akışını Ayarlar üzerinden tamamlayın.';
      healthColor = ext.textSecondary;
    } else {
      healthLine = 'Canlı entegrasyonlar dengede; ofis ilan akışı izleniyor.';
      healthColor = ext.accent.withValues(alpha: 0.92);
    }

    final syncHint = latestSync != null
        ? 'Son senkron: ${DateFormat('d MMM HH:mm', 'tr_TR').format(latestSync)}'
        : 'Son senkron kaydı henüz oluşmadı';

    final calm = attention == 0 && liveOk > 0;
    final borderColor = calm
        ? ext.accent.withValues(alpha: 0.32)
        : ext.border.withValues(alpha: 0.55);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space4),
        child: Semantics(
          label:
              'Bağlantı hazırlığı. $connectionLine. $healthLine. $syncHint. Ayarlar için çift dokunun.',
          button: true,
          child: Material(
            color: Colors.transparent,
            borderRadius:
                BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRouter.routeConnectedAccounts);
              },
              borderRadius:
                  BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
              splashColor: ext.accent.withValues(alpha: 0.08),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
                  color: calm
                      ? ext.accent.withValues(alpha: 0.04)
                      : ext.surfaceElevated,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (calm)
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(
                                  DashboardLayoutTokens.radiusCardM - 1),
                            ),
                            color: ext.accent.withValues(alpha: 0.75),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.space5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.link_rounded,
                                      size: 22, color: ext.accent),
                                  const SizedBox(width: DesignTokens.space3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bağlantı hazırlığı',
                                          style: AppTypography.cardHeading(
                                              context),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'İlan kanalları ve senkron durumu',
                                          style: AppTypography.meta(context)
                                              .copyWith(
                                            color: ext.textTertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      context.push(
                                          AppRouter.routeConnectedAccounts);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      minimumSize: const Size(44, 40),
                                      foregroundColor: ext.accent,
                                    ),
                                    child: const Text('Yönet'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DesignTokens.space4),
                              Text(
                                connectionLine,
                                style: AppTypography.bodyStrong(context)
                                    .copyWith(height: 1.35),
                              ),
                              const SizedBox(height: DesignTokens.space2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 18,
                                    color: healthColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, c) {
                                        final narrow = c.maxWidth < 300;
                                        final ts =
                                            MediaQuery.textScalerOf(context);
                                        final ratio = ts.scale(
                                                DesignTokens.fontSizeBase) /
                                            DesignTokens.fontSizeBase;
                                        return Text(
                                          healthLine,
                                          style: AppTypography.body(context)
                                              .copyWith(
                                            color: healthColor,
                                            height: 1.38,
                                            fontWeight: FontWeight.w600,
                                            fontSize: narrow || ratio > 1.15
                                                ? DesignTokens.fontSizeSm
                                                : null,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DesignTokens.space2),
                              Text(
                                syncHint,
                                style: AppTypography.meta(context).copyWith(
                                  color: ext.textTertiary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.space3),
                              Text(
                                'İçe aktarma ve geçmiş: Ayarlar → İlanlar ve platform bağlantıları',
                                style: AppTypography.meta(context).copyWith(
                                  color: ext.textTertiary.withValues(alpha: 0.95),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
