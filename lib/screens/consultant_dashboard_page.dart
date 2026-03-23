import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli – Benim Özetim: günlük odak, takip sayısı, hızlı erişim, piyasa.
class ConsultantDashboardPage extends ConsumerWidget {
  const ConsultantDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    final user = ref.watch(currentUserProvider.select((v) => v.valueOrNull));
    final greeting = user?.email != null
        ? 'Merhaba, ${user!.email!.split('@').first}'
        : 'Merhaba';
    // Ekran görüntüsü: GoRouter `_AnalyticsRouteObserver` (route `name` = matchedLocation).
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).t('my_summary'),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: AppLocalizations.of(context).t('notifications'),
                          button: true,
                          child: IconButton(
                            onPressed: () => context.push(AppRouter.routeNotifications),
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: textSecondary,
                              size: 26,
                            ),
                            tooltip: AppLocalizations.of(context).t('notifications'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _ConsultantTeamLine(),
                    const SizedBox(height: 8),
                    const _TodayKpiRow(),
                    const SizedBox(height: 8),
                    _TodayBriefLine(resurrectionAsync: resurrectionAsync),
                    const SizedBox(height: 8),
                    const _QuickActionsRow(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _QuickStatsCard(resurrectionAsync: resurrectionAsync),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _WeeklyGoalCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _PipelineChampionCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space6)),
            const SliverToBoxAdapter(child: MasterTicker()),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(child: FinanceBar()),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: MarketPulsePanel(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: DiscoveryPanel(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space4)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _ConsultantAcademyCard(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.space8)),
          ],
        ),
      ),
    );
  }
}

/// Danışmanın ekip ve yönetici bilgisi (teamId/managerId varsa).
class _ConsultantTeamLine extends ConsumerWidget {
  const _ConsultantTeamLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTertiary = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();
    final userDocAsync = ref.watch(userDocStreamProvider(uid));
    return userDocAsync.when(
      data: (doc) {
        if (doc == null) return const SizedBox.shrink();
        final teamId = doc.teamId;
        if (teamId == null || teamId.isEmpty) return const SizedBox.shrink();
        return StreamBuilder(
          stream: FirestoreService.teamDocStream(teamId),
          builder: (context, teamSnap) {
            final team = teamSnap.data;
            return FutureBuilder<UserDoc?>(
              future: doc.managerId != null && doc.managerId!.isNotEmpty
                  ? UserRepository.getUserDoc(doc.managerId!)
                  : Future.value(),
              builder: (context, managerSnap) {
                final teamName = team?.name ?? '—';
                final managerName = managerSnap.data?.name ?? managerSnap.data?.email ?? '—';
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${AppLocalizations.of(context).t('label_team')}: $teamName · ${AppLocalizations.of(context).t('label_manager')}: $managerName',
                    style: TextStyle(
                      color: textTertiary,
                      fontSize: DesignTokens.fontSizeXs,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TodayBriefLine extends StatelessWidget {
  const _TodayBriefLine({required this.resurrectionAsync});
  final AsyncValue<List<dynamic>> resurrectionAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final textTertiary = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
    final count = resurrectionAsync.valueOrNull?.length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3, vertical: DesignTokens.space2),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.today_rounded, size: 18, color: DesignTokens.primary),
          const SizedBox(width: DesignTokens.space2),
          Text(
            AppLocalizations.of(context).tArgs('today_follows', [count.toString()]),
            style: TextStyle(
              color: textSecondary,
              fontSize: DesignTokens.fontSizeSm,
            ),
          ),
          Text(
            count > 0 ? ' · ' : '',
            style: TextStyle(color: textTertiary),
          ),
          if (count > 0)
            Text(
              AppLocalizations.of(context).t('today_brief'),
              style: TextStyle(
                color: textTertiary,
                fontSize: DesignTokens.fontSizeXs,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bugünkü hızlı KPI şeridi: çağrı, görev, pipeline.
class _TodayKpiRow extends ConsumerWidget {
  const _TodayKpiRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final textStyleLabel = TextStyle(
      color: textSecondary,
      fontSize: DesignTokens.fontSizeXs,
    );
    final textStyleValue = TextStyle(
      color: textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: DesignTokens.fontSizeMd,
    );
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: FirestoreService.todayCallsCountStream(),
            builder: (context, snap) {
              final value = snap.data ?? 0;
              return _KpiChip(
                icon: Icons.phone_in_talk_rounded,
                label: AppLocalizations.of(context).t('today_calls'),
                value: '$value',
                labelStyle: textStyleLabel,
                valueStyle: textStyleValue,
              );
            },
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestoreService.tasksByAdvisorStream(uid),
            builder: (context, snap) {
              final value = snap.data?.docs.length ?? 0;
              return _KpiChip(
                icon: Icons.task_alt_rounded,
                label: AppLocalizations.of(context).t('open_tasks'),
                value: '$value',
                labelStyle: textStyleLabel,
                valueStyle: textStyleValue,
              );
            },
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestoreService.pipelineItemsByAdvisorStream(uid),
            builder: (context, snap) {
              final value = snap.data?.docs.length ?? 0;
              return _KpiChip(
                icon: Icons.account_tree_rounded,
                label: AppLocalizations.of(context).t('active_pipeline'),
                value: '$value',
                labelStyle: textStyleLabel,
                valueStyle: textStyleValue,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DesignTokens.primary),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Yıldız danışman akademisi: kısa eğitim + motivasyon.
class _ConsultantAcademyCard extends StatelessWidget {
  const _ConsultantAcademyCard();

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
        border: Border.all(color: border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: DesignTokens.primary, size: 22),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  'Yıldız Danışman Akademisi',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Bugünün mikro eğitimi: İtiraz karşılama – “Fiyat yüksek”',
            style: TextStyle(
              color: textSecondary,
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
              color: textTertiary,
              fontSize: DesignTokens.fontSizeXs,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Divider(height: 1, color: border),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Önerilen aksiyon: Bugün bu script\'i kullanarak en az 3 “kararsız” müşterini tekrar ara. '
            'Notlarını CRM\'e yaz; haftalık değerlendirmede bunlara bakacağız.',
            style: TextStyle(
              color: textSecondary,
              fontSize: DesignTokens.fontSizeXs,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
                  ),
                  builder: (ctx) => DraggableScrollableSheet(
                    initialChildSize: 0.55,
                    minChildSize: 0.35,
                    maxChildSize: 0.92,
                    expand: false,
                    builder: (_, scroll) => SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.all(DesignTokens.space5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school_rounded, color: DesignTokens.primary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'İtiraz karşılama – “Fiyat yüksek”',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: DesignTokens.fontSizeMd,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Açılış cümlesi',
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“Anlıyorum; bütçenizi zorlamadan size uygun seçenekleri birlikte netleştirelim.”',
                            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.45),
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Adım adım',
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1) Empati: Müşterinin endişesini tekrar et; savunmaya geçme.\n\n'
                            '2) Çerçevele: Aynı bölgede son dönem kapanan örnekleri (m² fiyatı) kısaca paylaş.\n\n'
                            '3) Alternatif sun: Daha küçük metrekare veya komşu mahallede 1–2 seçenek öner.\n\n'
                            '4) Sonraki adım: “Yarın aynı saatte iki ilanı yerinde gösterebilir miyim?” diye net randevu iste.',
                            style: TextStyle(color: textTertiary, fontSize: 12, height: 1.5),
                          ),
                          const SizedBox(height: DesignTokens.space5),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push(AppRouter.routeCall);
                              },
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                              label: const Text('Magic Call ile uygula'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DesignTokens.primary,
                                foregroundColor: DesignTokens.inputTextOnGold,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primary,
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

/// Hızlı aksiyonlar: Magic Call ve Tüm Çağrılar.
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              AnalyticsService.instance.logEvent(AnalyticsEvents.magicCallTap);
              context.push(AppRouter.routeCall);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: DesignTokens.inputTextOnGold,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
            label: const Text(
              'Magic Call',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              AnalyticsService.instance.logEvent(AnalyticsEvents.consultantCallsTap);
              context.push(AppRouter.routeConsultantCalls);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: BorderSide(color: border.withValues(alpha: 0.8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text(
              'Tüm Çağrılarım',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyGoalCard extends ConsumerWidget {
  const _WeeklyGoalCard();

  static const int weeklyGoal = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return StreamBuilder<int>(
      stream: FirestoreService.agentWeeklyCallCountStream(uid),
      builder: (context, snap) {
        final current = snap.data ?? 0;
        final progress = weeklyGoal > 0 ? (current / weeklyGoal).clamp(0.0, 1.0) : 0.0;
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bu hafta',
                    style: TextStyle(color: textSecondary, fontSize: DesignTokens.fontSizeSm),
                  ),
                  Text(
                    '$current / $weeklyGoal çağrı',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: border,
                  valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PipelineChampionCard extends StatelessWidget {
  const _PipelineChampionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRouter.routePipeline);
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: DesignTokens.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surface,
                DesignTokens.primary.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: DesignTokens.gradientPrimary,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  color: DesignTokens.inputTextOnGold,
                  size: 26,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pipeline',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: DesignTokens.fontSizeLg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Satış hunisi · Aşamaları yönet',
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
                size: 16,
                color: DesignTokens.primary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.resurrectionAsync});

  final AsyncValue<List<dynamic>> resurrectionAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final textTertiary = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
    final count = resurrectionAsync.valueOrNull?.length ?? 0;
    final isLoading = resurrectionAsync.isLoading;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: DesignTokens.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takip listesi',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    if (isLoading)
                      Text(
                        'Takip listesi yükleniyor...',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                      )
                    else
                      Text(
                        count == 0
                            ? 'Şu an takip edilecek lead yok'
                            : '$count lead takip bekliyor',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                      ),
                  ],
                ),
              ),
              if (count > 0)
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRouter.routeResurrection);
                  },
                  child: const Text('Görüntüle'),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Magic Call ile aradığın müşterilerin özeti otomatik kaydedilir; '
            'takip sekmesinden sessiz kalan lead\'lere ulaşabilirsin.',
            style: TextStyle(
              color: textTertiary,
              fontSize: DesignTokens.fontSizeXs,
            ),
          ),
        ],
      ),
    );
  }
}
