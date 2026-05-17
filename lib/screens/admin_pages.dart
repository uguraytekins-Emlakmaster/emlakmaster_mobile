import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/pages/admin_consultants_page.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/pages/admin_teams_page.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Yönetici paneli – Ekonomi & Piyasa: kur, altın, piyasa nabzı, ticker.
class AdminEconomyPage extends StatelessWidget {
  const AdminEconomyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final bg = ext.background;
    final fg = ext.textPrimary;
    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        title: const Text('Piyasa Nabzı'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        children: [
          const MasterTicker(),
          const SizedBox(height: DesignTokens.space6),
          const FinanceBar(),
          const SizedBox(height: DesignTokens.space6),
          const MarketPulsePanel(),
          const SizedBox(height: DesignTokens.space6),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            child: Text(
              'Kur, altın ve seçili endeksler canlı akar; ayrıntılar İçgörüler alanında derlenir.',
              style: AppTypography.body(context).copyWith(
                fontSize: DesignTokens.fontSizeSm,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yönetici paneli – Raporlar & Ekip: performans, ekip özeti, audit.
class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(displayRoleProvider).valueOrNull ?? AppRole.guest;
    final canManageTeams = FeaturePermission.canManageTeams(role);
    final canViewPipeline = FeaturePermission.canViewPipeline(role);
    final showAuditComingSoon = FeaturePermission.canViewAuditLog(role);
    final canViewCallCenter = FeaturePermission.canViewAllCalls(role);

    final ext = AppThemeExtension.of(context);
    final bg = ext.background;
    final bottomPad = DashboardLayoutTokens.shellScrollBottomPadding(context);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space6,
          DesignTokens.space3,
          DesignTokens.space6,
          bottomPad,
        ),
        children: [
          const PremiumPageHeader(
            title: 'İçgörüler ve Kadro',
            subtitle: 'Performansı izle, ekibini güçlendir.',
          ),
          const _AdminReportsPerformanceCard(),
          const SizedBox(height: DesignTokens.space4),
          if (canViewCallCenter) ...[
            PremiumIconTile(
              icon: Icons.phone_callback_rounded,
              title: ProductLabels.callCenter,
              subtitle: 'Danışman, müşteri ve kayıt görünümleri tek yerde.',
              onTap: () => context.push(AppRouter.routeCommandCenter),
            ),
            const SizedBox(height: DesignTokens.space4),
          ],
          if (canManageTeams)
            StreamBuilder<List<TeamDoc>>(
              stream: FirestoreService.teamsStream(),
              builder: (context, snap) {
                final teams = snap.data ?? [];
                if (teams.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space4),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusLg),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AdminTeamsPage()),
                        );
                      },
                      child: const _SectionCard(
                        featured: true,
                        icon: Icons.group_add_rounded,
                        title: 'İlk kadroyu kurun',
                        subtitle: 'Rolleri ve üyeleri tek akıştan yönetin.',
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          const _AdminReportsPerfSection(),
          const SizedBox(height: DesignTokens.space4),
          PremiumIconTile(
            icon: Icons.groups_rounded,
            title: 'Kadro ve yetkiler',
            subtitle: 'Danışmanlar, ekip dağılımı ve erişim ayarları',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminConsultantsPage()),
              );
            },
          ),
          if (canManageTeams) ...[
            const SizedBox(height: DesignTokens.space4),
            PremiumIconTile(
              icon: Icons.group_work_rounded,
              title: 'Ekipler',
              subtitle: 'Kurulum, lider ataması ve ekip yapısı',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminTeamsPage()),
                );
              },
            ),
          ],
          if (showAuditComingSoon) ...[
            const SizedBox(height: DesignTokens.space4),
            _ComingSoonReportCard(
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
                  type: PremiumActionFeedbackType.info,
                  useSheet: false,
                );
              },
            ),
          ],
          if (canViewPipeline) ...[
            const SizedBox(height: DesignTokens.space4),
            PremiumIconTile(
              icon: Icons.view_kanban_rounded,
              title: 'Fırsat hattı',
              subtitle: 'Canlı kanban görünümü; aşamalar ve açık fırsatlar',
              onTap: () => context.push(AppRouter.routePipeline),
            ),
          ],
          const SizedBox(height: DesignTokens.space6),
          PremiumSurfaceCard(
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
                  onPressed: () => context.push(AppRouter.routeCommandCenter),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _AdminReportsPerformanceCard extends StatelessWidget {
  const _AdminReportsPerformanceCard();

  @override
  Widget build(BuildContext context) {
    return PremiumSurfaceCard(
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
            subtitle:
                'Çağrı ve kapanış eğilimleri için ayrıntılı rapor yakında',
            onExplore: () => context.push(AppRouter.routeRainbowAnalytics),
          ),
        ],
      ),
    );
  }
}

/// Yönetici performans özeti: en az bir çağrı özeti veya işlem kaydı yoksa boş durum.
class _AdminReportsPerfSection extends StatefulWidget {
  const _AdminReportsPerfSection();

  @override
  State<_AdminReportsPerfSection> createState() =>
      _AdminReportsPerfSectionState();
}

class _AdminReportsPerfSectionState extends State<_AdminReportsPerfSection> {
  int _streamEpoch = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey<int>(_streamEpoch),
      stream: FirestoreService.callSummariesSampleStream(),
      builder: (context, summariesSnap) {
        if (summariesSnap.hasError) {
          return _AdminPerfErrorCard(
            onRetry: () => setState(() => _streamEpoch++),
          );
        }
        if (!summariesSnap.hasData) {
          return const _AdminPerfLoadingCard();
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.dealsSampleStream(),
          builder: (context, dealsSnap) {
            if (dealsSnap.hasError) {
              return _AdminPerfErrorCard(
                onRetry: () => setState(() => _streamEpoch++),
              );
            }
            if (!dealsSnap.hasData) {
              return const _AdminPerfLoadingCard();
            }
            final hasSummaries = summariesSnap.data!.docs.isNotEmpty;
            final hasDeals = dealsSnap.data!.docs.isNotEmpty;
            if (!hasSummaries && !hasDeals) {
              final l10n = AppLocalizations.of(context);
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space4),
                  child: EmptyState(
                    compact: true,
                    grouped: true,
                    icon: Icons.analytics_outlined,
                    title: l10n.t('empty_reports_title'),
                    subtitle: l10n.t('empty_reports_sub'),
                    outlinedActionLabel: l10n.t('empty_reports_cta'),
                    onOutlinedAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminConsultantsPage(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space4),
              child: _ComingSoonReportCard(
                icon: Icons.analytics_rounded,
                title: 'Performans görünümü',
                subtitle:
                    'Çağrı ve kapanış eğilimleri için ayrıntılı rapor yakında',
                onExplore: () => context.push(AppRouter.routeRainbowAnalytics),
              ),
            );
          },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Container(
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
      ),
    );
  }
}

class _AdminPerfErrorCard extends StatelessWidget {
  const _AdminPerfErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space4),
        child: EmptyState(
          compact: true,
          grouped: true,
          icon: Icons.cloud_off_outlined,
          title: 'İçgörü verisine ulaşılamadı',
          subtitle: 'Bağlantıyı kontrol edip yeniden deneyin.',
          actionLabel: 'Yeniden dene',
          onAction: onRetry,
        ),
      ),
    );
  }
}

/// Rapor kartı: henüz ekranı olmayan veya yakında tamamlanacak özellikler.
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
    final ext = AppThemeExtension.of(context);
    final surface = ext.surface;
    final border = ext.border;
    final muted = ext.textSecondary.withValues(alpha: 0.88);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        onTap: () {
          if (onExplore != null) {
            onExplore!();
            return;
          }
          showPremiumComingSoon(
            context,
            title: title,
            message: subtitle,
          );
        },
        child: Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: border.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: ext.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(icon, color: muted, size: DesignTokens.iconMd),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.cardHeading(context).copyWith(
                          fontSize: DesignTokens.fontSizeMd,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusPill),
                        border:
                            Border.all(color: border.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        'Yakında',
                        style: AppTypography.metricLabel(context).copyWith(
                          fontSize: DesignTokens.fontSizeXs,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.titleSubtitleGap),
                Text(
                  subtitle,
                  style: AppTypography.body(context).copyWith(
                    fontSize: DesignTokens.fontSizeSm,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
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

  /// Vurgulu CTA kartı (ör. henüz ekip yokken).
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final surface = ext.surface;
    final borderColor = featured
        ? ext.accent.withValues(alpha: 0.32)
        : ext.border.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: ext.accent.withValues(alpha: featured ? 0.14 : 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(icon, color: ext.accent, size: DesignTokens.iconLg),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardHeading(context).copyWith(
                    fontSize: DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: featured ? ext.accent : null,
                  ),
                ),
                const SizedBox(height: DesignTokens.titleSubtitleGap),
                Text(
                  subtitle,
                  style: AppTypography.body(context).copyWith(
                    fontSize: DesignTokens.fontSizeSm,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: DesignTokens.iconSm,
            color: ext.textTertiary,
          ),
        ],
      ),
    );
  }
}
