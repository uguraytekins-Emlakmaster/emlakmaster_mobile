import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_quick_routes.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/screens/providers/admin_reports_perf_provider.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Yönetici paneli – Raporlar & Kadro: executive overview surfaces.
class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleProvider).valueOrNull ?? AppRole.guest;
    final canManageTeams = FeaturePermission.canManageTeams(role);
    final canViewPipeline = FeaturePermission.canViewPipeline(role);
    final showAuditComingSoon = FeaturePermission.canViewAuditLog(role);
    final canViewCallCenter = FeaturePermission.canViewAllCalls(role);
    final teamsAsync = ref.watch(adminConsultantsTeamsProvider);

    final bottomPad = DashboardLayoutTokens.shellScrollBottomPadding(context);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ShellScreenReadyListener(
          screenName: 'admin_reports',
          provider: adminReportsPerfProvider,
          child: SafeArea(
            child: CustomScrollView(
              cacheExtent: 320,
              slivers: [
                const SliverToBoxAdapter(
                  child: PremiumAdminCommandHeader(
                    title: 'İçgörüler ve Kadro',
                    subtitle: 'Performans · ekip özeti · denetim erişimi',
                  ),
                ),
                SliverToBoxAdapter(
                  child: teamsAsync.maybeWhen(
                    data: (teams) => PremiumAdminSectionLabel(
                      label: 'Kadro durumu',
                      secondary: teams.isEmpty
                          ? 'Ekip kurulumu bekleniyor'
                          : '${teams.length} ekip kaydı',
                    ),
                    orElse: () => const PremiumAdminSectionLabel(
                      label: 'Kadro durumu',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _AdminReportsPerformanceCard()),
                if (canViewCallCenter)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: PremiumIconTile(
                        icon: Icons.phone_callback_rounded,
                        title: ProductLabels.callCenter,
                        subtitle: 'Danışman, müşteri ve kayıt görünümleri tek yerde.',
                        onTap: () => context.push(AppRouter.routeCommandCenter),
                      ),
                    ),
                  ),
                if (canManageTeams)
                  const SliverToBoxAdapter(child: _AdminReportsTeamsEmptyCard()),
                const SliverToBoxAdapter(child: _AdminReportsPerfSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: PremiumIconTile(
                      icon: Icons.groups_rounded,
                      title: 'Kadro ve yetkiler',
                      subtitle: 'Danışmanlar, ekip dağılımı ve erişim ayarları',
                      onTap: () => context.push(AppRouter.routeAdminConsultants),
                    ),
                  ),
                ),
                if (canManageTeams)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: PremiumIconTile(
                        icon: Icons.group_work_rounded,
                        title: 'Ekipler',
                        subtitle: 'Kurulum, lider ataması ve ekip yapısı',
                        onTap: () => context.push(AppRouter.routeAdminTeams),
                      ),
                    ),
                  ),
                if (showAuditComingSoon)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _ComingSoonReportCard(
                        icon: Icons.history_rounded,
                        title: 'İşlem kaydı',
                        subtitle: 'Sistem hareketleri için ayrıntılı görünüm yakında',
                        onExplore: () {
                          context.push(AppRouter.routeCommandCenter);
                          showPremiumActionFeedback(
                            context,
                            title: 'Çağrı kayıtları açık',
                            message:
                                'Tam denetim günlüğü hazırlanıyor. Şimdilik Komuta Merkezi çağrı kayıtlarından ekip hareketlerini izleyebilirsiniz.',
                            useSheet: false,
                          );
                        },
                      ),
                    ),
                  ),
                if (canViewPipeline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: PremiumIconTile(
                        icon: Icons.view_kanban_rounded,
                        title: 'Fırsat hattı',
                        subtitle: 'Canlı kanban görünümü; aşamalar ve açık fırsatlar',
                        onTap: () => context.push(AppRouter.routePipeline),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: PremiumAdminSectionLabel(
                    label: 'Hızlı geçiş',
                    secondary: 'Komuta yüzeyleri',
                  ),
                ),
                const SliverToBoxAdapter(child: PremiumAdminQuickRoutes()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                  sliver: SliverToBoxAdapter(
                    child: _AdminReportsFooterCta(
                      onOpenReports: () => context.push(AppRouter.routeCommandCenter),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminReportsFooterCta extends StatelessWidget {
  const _AdminReportsFooterCta({required this.onOpenReports});

  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return PremiumSurfaceCard(
      goldBorder: true,
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: ext.accent, size: 28),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veriler seninle anlam kazanır.',
                  style: AppTypography.cardHeading(context),
                ),
                Text(
                  'Raporlarını keşfet, ekibini yönet, büyümeyi hızlandır.',
                  style: AppTypography.meta(context),
                ),
              ],
            ),
          ),
          PremiumCtaButton(
            expanded: false,
            label: 'Raporları aç',
            icon: Icons.bar_chart_rounded,
            onPressed: onOpenReports,
          ),
        ],
      ),
    );
  }
}

class _AdminReportsTeamsEmptyCard extends ConsumerWidget {
  const _AdminReportsTeamsEmptyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(adminConsultantsTeamsProvider);
    return teamsAsync.when(
      data: (teams) {
        if (teams.isNotEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            onTap: () => context.push(AppRouter.routeAdminTeams),
            child: const _SectionCard(
              featured: true,
              icon: Icons.group_add_rounded,
              title: 'İlk kadroyu kurun',
              subtitle: 'Rolleri ve üyeleri tek akıştan yönetin.',
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AdminReportsPerformanceCard extends StatelessWidget {
  const _AdminReportsPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: PremiumSurfaceCard(
        goldBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumSectionHeader(
              label: 'Genel performans',
              icon: Icons.insights_rounded,
            ),
            Text(
              'Çağrı ve kapanış kayıtları biriktikçe ekip performans özeti burada derlenecek.',
              style: AppTypography.meta(context).copyWith(height: 1.4),
            ),
            const SizedBox(height: DesignTokens.space3),
            _ComingSoonReportCard(
              icon: Icons.analytics_rounded,
              title: 'Performans görünümü',
              subtitle: 'Çağrı ve kapanış eğilimleri için ayrıntılı rapor yakında',
              onExplore: () => context.push(AppRouter.routeRainbowAnalytics),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminReportsPerfSection extends ConsumerWidget {
  const _AdminReportsPerfSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(adminReportsPerfProvider);
    return perfAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _AdminPerfLoadingCard(),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _AdminPerfErrorCard(
          onRetry: () {
            ref.invalidate(adminCallSummariesSampleProvider);
            ref.invalidate(adminDealsSampleProvider);
          },
        ),
      ),
      data: (perf) {
        if (!perf.hasAnyData) {
          final l10n = AppLocalizations.of(context);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: EmptyState(
              compact: true,
              grouped: true,
              icon: Icons.analytics_outlined,
              title: l10n.t('empty_reports_title'),
              subtitle: l10n.t('empty_reports_sub'),
              outlinedActionLabel: l10n.t('empty_reports_cta'),
              onOutlinedAction: () =>
                  context.push(AppRouter.routeAdminConsultants),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _ComingSoonReportCard(
            icon: Icons.analytics_rounded,
            title: 'Performans görünümü',
            subtitle: 'Çağrı ve kapanış eğilimleri için ayrıntılı rapor yakında',
            onExplore: () => context.push(AppRouter.routeRainbowAnalytics),
          ),
        );
      },
    );
  }
}

class _AdminPerfLoadingCard extends StatelessWidget {
  const _AdminPerfLoadingCard();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: ext.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 200,
                  height: 14,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                const SizedBox(height: DesignTokens.space2),
                SkeletonLoader(
                  width: 160,
                  height: 12,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPerfErrorCard extends StatelessWidget {
  const _AdminPerfErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      compact: true,
      grouped: true,
      icon: Icons.cloud_off_outlined,
      title: 'İçgörü verisine ulaşılamadı',
      subtitle: 'Bağlantıyı kontrol edip yeniden deneyin.',
      actionLabel: 'Yeniden dene',
      onAction: onRetry,
    );
  }
}

class _ComingSoonReportCard extends StatelessWidget {
  const _ComingSoonReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onExplore,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return PremiumIconTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      badge: 'Yakında',
      onTap: onExplore,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.featured = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: featured
            ? ext.accent.withValues(alpha: 0.08)
            : ext.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: featured
              ? ext.accent.withValues(alpha: 0.35)
              : ext.border.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: ext.accent, size: 28),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardHeading(context)),
                Text(subtitle, style: AppTypography.meta(context)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: ext.textTertiary),
        ],
      ),
    );
  }
}
