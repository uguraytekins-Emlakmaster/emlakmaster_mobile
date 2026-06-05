import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Haftalık hedef + takip istatistiği — yan yana (geniş) veya alt alta (dar).
class ConsultantDashboardGoalStatsRow extends StatelessWidget {
  const ConsultantDashboardGoalStatsRow({super.key});

  static const double sideBySideBreakpoint = 520;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= sideBySideBreakpoint) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ConsultantDashboardWeeklyGoalCard()),
              SizedBox(width: DesignTokens.space2),
              Expanded(child: ConsultantDashboardQuickStatsCard(compact: true)),
            ],
          );
        }
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsultantDashboardWeeklyGoalCard(),
            SizedBox(height: DesignTokens.space2),
            ConsultantDashboardQuickStatsCard(compact: true),
          ],
        );
      },
    );
  }
}

class ConsultantDashboardWeeklyGoalCard extends ConsumerWidget {
  const ConsultantDashboardWeeklyGoalCard({super.key});

  static const int weeklyGoal = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final current = ref.watch(
      agentWeeklyCallCountProvider(uid).select((a) => a.valueOrNull ?? 0),
    );
    final progress =
        weeklyGoal > 0 ? (current / weeklyGoal).clamp(0.0, 1.0) : 0.0;
    return Container(
      constraints: const BoxConstraints(
          minHeight: DashboardLayoutTokens.minHeightOperationalCard),
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space5, vertical: DesignTokens.space3),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius:
            BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bu hafta',
                  style: AppTypography.metricLabel(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$current / $weeklyGoal çağrı',
                  style: AppTypography.bodyStrong(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: ext.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(ext.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class ConsultantDashboardQuickStatsCard extends ConsumerWidget {
  const ConsultantDashboardQuickStatsCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      resurrectionQueueProvider.select((a) => a.valueOrNull?.length ?? 0),
    );
    final isLoading = ref.watch(
      resurrectionQueueProvider.select((a) => a.isLoading),
    );
    final ext = AppThemeExtension.of(context);
    final pad = compact ? DesignTokens.space4 : DesignTokens.space5;
    final iconBox = compact ? DesignTokens.space2 : DesignTokens.space3;
    final iconSize = compact ? 20.0 : 24.0;
    void openFollowUp() {
      AppFeedback.mediumImpact();
      ref
          .read(mainShellShortcutProvider.notifier)
          .enqueue(MainShellShortcut.openFollowUpTab);
      context.go(AppRouter.routeHome);
    }

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (count > 0) {
              openFollowUp();
            } else {
              showPremiumActionFeedback(
                context,
                title: ProductLabels.followUp,
                message:
                    'Şu an yeniden temas bekleyen müşteri yok. Yeni takip kayıtları burada görünecek.',
              );
            }
          },
          borderRadius:
              BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
          child: Container(
            constraints: BoxConstraints(
              minHeight: compact
                  ? DashboardLayoutTokens.minHeightOperationalCard
                  : DashboardLayoutTokens.minHeightInsightCard,
            ),
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius:
                  BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
              border: Border.all(color: ext.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconBox),
                      decoration: BoxDecoration(
                        color: ext.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                            DashboardLayoutTokens.radiusCardS),
                      ),
                      child: Icon(
                        Icons.replay_rounded,
                        color: ext.accent,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(
                        width:
                            compact ? DesignTokens.space3 : DesignTokens.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ProductLabels.followUp,
                            style: AppTypography.cardHeading(context).copyWith(
                              fontSize: compact
                                  ? DesignTokens.fontSizeMd
                                  : DesignTokens.fontSizeLg,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isLoading)
                            Text(
                              'Takip akışı yükleniyor…',
                              style: AppTypography.body(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              count == 0
                                  ? 'Şu an öne çekilecek sessiz müşteri yok'
                                  : '$count müşteri yeniden temas bekliyor',
                              style: AppTypography.body(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (count > 0)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space2,
                              vertical: DesignTokens.space1),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: ext.accent,
                        ),
                        onPressed: openFollowUp,
                        child: const Text('Görüntüle'),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Akıllı görüşmelerin özeti otomatik kaydedilir; '
                    'gelişimi duran müşterilere bu alandan yeniden dokunabilirsin.',
                    style: TextStyle(
                      color: ext.textTertiary,
                      fontSize: DesignTokens.fontSizeXs,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    'Sessiz kalan müşteriler için yeniden temas alanı.',
                    style: TextStyle(
                      color: ext.textTertiary,
                      fontSize: DesignTokens.fontSizeXs,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConsultantDashboardPipelineChampionCard extends StatelessWidget {
  const ConsultantDashboardPipelineChampionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppFeedback.mediumImpact();
          context.push(AppRouter.routePipeline);
        },
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
        child: Container(
          constraints: const BoxConstraints(
              minHeight: DashboardLayoutTokens.minHeightInsightCard),
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4, vertical: DesignTokens.space4),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius:
                BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: ext.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Fırsat hattı',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Satış akışı · aşamaları tek yerden yönet',
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: ext.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsultantDashboardAcademyCard extends StatelessWidget {
  const ConsultantDashboardAcademyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardL),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: ext.accent, size: 22),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  'Yıldız Danışman Akademisi',
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Bugünün mikro eğitimi: İtiraz karşılama – “Fiyat yüksek”',
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            '1) Önce müşteriyi anladığını göster.\n'
            '2) Aynı bölgedeki örnek satışlarla fiyatı çerçevele.\n'
            '3) Alternatif (daha küçük / farklı bölge) sun.',
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: DesignTokens.fontSizeXs,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Divider(height: 1, color: ext.borderSubtle),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Önerilen aksiyon: Bugün bu script\'i kullanarak en az 3 “kararsız” müşterini tekrar ara. '
            'Notlarını CRM\'e yaz; haftalık değerlendirmede bunlara bakacağız.',
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeXs,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                AppFeedback.lightImpact();
                showPremiumDraggableBottomSheet<void>(
                  context: context,
                  initialChildSize: 0.55,
                  builder: (ctx, scroll) => SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.space5,
                        DesignTokens.space2,
                        DesignTokens.space5,
                        DesignTokens.space6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PremiumBottomSheetHandle(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: ext.accent.withValues(alpha: 0.55),
                                size: DesignTokens.iconLg,
                              ),
                              const SizedBox(width: DesignTokens.space3),
                              const Expanded(
                                child: PremiumSheetHeader(
                                  compact: true,
                                  title: 'İtiraz karşılama — “Fiyat yüksek”',
                                  subtitle: 'Mikro eğitim · bugünün script’i',
                                ),
                              ),
                              IconButton(
                                tooltip: 'Kapat',
                                style: IconButton.styleFrom(
                                  foregroundColor: ext.textTertiary,
                                ),
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Açılış cümlesi',
                            style: AppTypography.cardHeading(context).copyWith(
                              fontSize: DesignTokens.fontSizeSm,
                              color: ext.textPrimary,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.titleSubtitleGap),
                          Text(
                            '“Anlıyorum; bütçenizi zorlamadan size uygun seçenekleri birlikte netleştirelim.”',
                            style: AppTypography.body(context).copyWith(
                              color: ext.textSecondary,
                              fontSize: DesignTokens.fontSizeSm,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Adım adım',
                            style: AppTypography.cardHeading(context).copyWith(
                              fontSize: DesignTokens.fontSizeSm,
                              color: ext.textPrimary,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          Text(
                            '1) Empati: Müşterinin endişesini tekrar edin; savunmaya geçmeyin.\n\n'
                            '2) Çerçevele: Aynı bölgede son dönem kapanan örnekleri (m² fiyatı) kısaca paylaşın.\n\n'
                            '3) Alternatif: Daha küçük metrekare veya komşu mahallede 1–2 seçenek önerin.\n\n'
                            '4) Sonraki adım: “Yarın aynı saatte iki ilanı yerinde gösterebilir miyim?” diye net randevu isteyin.',
                            style: AppTypography.body(context).copyWith(
                              color: ext.textTertiary,
                              fontSize: DesignTokens.fontSizeSm,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space5),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push(
                                  AppRouter.routeCall,
                                  extra: const {
                                    'inAppCrmSession': true,
                                    'startedFromScreen': 'consultant_dashboard',
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.phone_in_talk_rounded,
                                size: DesignTokens.iconMd,
                              ),
                              label: const Text('Akıllı görüşme ile uygula'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ext.accent,
                                foregroundColor: ext.onBrand,
                                minimumSize: const Size(double.infinity, 48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: DesignTokens.space3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusControl,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: ext.accent,
              ),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
              label: const Text(
                'Detaylı eğitimi aç',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
