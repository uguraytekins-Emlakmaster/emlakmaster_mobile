import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/pages/admin_consultants_page.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/pages/admin_teams_page.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/shared/widgets/skeleton_loader.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici paneli – Ekonomi & Piyasa: kur, altın, piyasa nabzı, ticker.
class AdminEconomyPage extends StatelessWidget {
  const AdminEconomyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final fg = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final secondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        title: const Text('Ekonomi & Piyasa'),
        elevation: 0,
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
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            child: Text(
              'Döviz, faiz ve emlak piyasası verileri anlık güncellenir. '
              'Raporlar sekmesinden detaylı analizlere ulaşabilirsiniz.',
              style: TextStyle(
                color: secondary,
                fontSize: DesignTokens.fontSizeSm,
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
    final currentRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    final canManageTeams = FeaturePermission.canManageTeams(currentRole);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final fg = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        title: const Text('Raporlar & Ekip'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        children: [
          if (canManageTeams)
            StreamBuilder<List<TeamDoc>>(
              stream: FirestoreService.teamsStream(),
              builder: (context, snap) {
                final teams = snap.data ?? [];
                if (teams.isEmpty) {
                  final cardSurface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
                  final cardSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminTeamsPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.space5),
                        decoration: BoxDecoration(
                          color: cardSurface,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group_add_rounded, color: DesignTokens.primary, size: 32),
                            const SizedBox(width: DesignTokens.space4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ekiplerini kur',
                                    style: TextStyle(
                                      color: DesignTokens.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: DesignTokens.fontSizeMd,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Henüz ekip yok. İlk ekibinizi oluşturmak için buraya tıklayın.',
                                    style: TextStyle(
                                      color: cardSecondary,
                                      fontSize: DesignTokens.fontSizeSm,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DesignTokens.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          const _AdminReportsPerfSection(),
          const SizedBox(height: DesignTokens.space4),
          InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminConsultantsPage()),
              );
            },
            child: const _SectionCard(
              icon: Icons.groups_rounded,
              title: 'Danışmanlar & Ekipler',
              subtitle: 'Danışman listesi, ekip atamaları ve rol yönetimi',
            ),
          ),
          if (canManageTeams) ...[
            const SizedBox(height: DesignTokens.space4),
            InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminTeamsPage()),
                );
              },
              child: const _SectionCard(
                icon: Icons.group_work_rounded,
                title: 'Ekipler',
                subtitle: 'Ekip oluşturma, yönetici atama ve üye yönetimi',
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.space4),
          const _SectionCard(
            icon: Icons.history_rounded,
            title: 'Audit log',
            subtitle: 'Sistem ve kullanıcı işlem geçmişi',
          ),
          const SizedBox(height: DesignTokens.space4),
          const _SectionCard(
            icon: Icons.pie_chart_rounded,
            title: 'Pipeline raporları',
            subtitle: 'Huni analizi, oranlar ve tahminler',
          ),
        ],
      ),
    );
  }
}

/// Yönetici performans özeti: en az bir çağrı özeti veya işlem kaydı yoksa boş durum.
class _AdminReportsPerfSection extends StatelessWidget {
  const _AdminReportsPerfSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.callSummariesSampleStream(),
      builder: (context, summariesSnap) {
        if (summariesSnap.hasError) {
          return const _AdminPerfErrorCard();
        }
        if (!summariesSnap.hasData) {
          return const _AdminPerfLoadingCard();
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.dealsSampleStream(),
          builder: (context, dealsSnap) {
            if (dealsSnap.hasError) {
              return const _AdminPerfErrorCard();
            }
            if (!dealsSnap.hasData) {
              return const _AdminPerfLoadingCard();
            }
            final hasSummaries = summariesSnap.data!.docs.isNotEmpty;
            final hasDeals = dealsSnap.data!.docs.isNotEmpty;
            if (!hasSummaries && !hasDeals) {
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space4),
                  child: EmptyState(
                    compact: true,
                    icon: Icons.analytics_outlined,
                    title: 'Henüz rapor verisi yok',
                    subtitle:
                        'Çağrı özeti veya işlem kaydı oluştuğunda özet metrikler burada görünecek.',
                    outlinedActionLabel: 'Yeni kayıt ekle',
                    onOutlinedAction: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rapor kaydı oluşturma yakında.'),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.space4),
              child: _SectionCard(
                icon: Icons.analytics_rounded,
                title: 'Performans özeti',
                subtitle: 'Aylık/heftalık çağrı, görüşme ve kapanış metrikleri',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space5),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: border),
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
                  const SizedBox(height: 8),
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
  const _AdminPerfErrorCard();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.space4),
        child: EmptyState(
          compact: true,
          icon: Icons.cloud_off_outlined,
          title: 'Rapor verilerine ulaşılamadı',
          subtitle: 'Bağlantınızı kontrol edip sayfayı yenileyin.',
          outlinedActionLabel: 'Yeniden dene',
          onOutlinedAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sayfayı yenileyin veya aşağı çekin.')),
            );
          },
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final textTertiary = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(icon, color: DesignTokens.primary, size: 28),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: textTertiary,
          ),
        ],
      ),
    );
  }
}
