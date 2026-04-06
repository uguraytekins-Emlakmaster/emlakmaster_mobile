import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_dashboard_reminder.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/sync_delayed_customers_dashboard_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/execution_reminders_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/priority_call_signals_card.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli — [DashboardPage] ile aynı tasarım sistemi: **Hero** → **Operational** → **Insight** ([DashboardLayoutTokens]).
class ConsultantDashboardPage extends ConsumerWidget {
  const ConsultantDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final lean = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyV1LeanProduct] ?? true,
      ),
    );
    final summaryBottomPad =
        DashboardLayoutTokens.shellScrollBottomPadding(context);
    final user = ref.watch(currentUserProvider.select((v) => v.valueOrNull));
    final greeting = user?.email != null
        ? 'Merhaba, ${user!.email!.split('@').first}'
        : 'Merhaba';

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: RepaintBoundary(
          child: CustomScrollView(
          cacheExtent: 380,
          slivers: [
            // —— Layer 1–2: Hero + Operational (above-the-fold) ——
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DashboardLayoutTokens.horizontalPadding,
                  DashboardLayoutTokens.pageTopInset,
                  DashboardLayoutTokens.horizontalPadding,
                  DashboardLayoutTokens.pageBottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DashboardHeroHeader(greeting: greeting),
                    const SizedBox(height: DashboardLayoutTokens.gapHeroToOperational),
                    const PostCallCaptureDashboardReminder(),
                    const SizedBox(height: DashboardLayoutTokens.gapOperationalTight),
                    const _ConsultantTeamLine(),
                    const SizedBox(height: DashboardLayoutTokens.gapOperationalTight),
                    const _TodayKpiRow(),
                    const SizedBox(height: DashboardLayoutTokens.gapOperationalTight),
                    const ExecutionRemindersCard(surface: ExecutionReminderSurface.consultant),
                    const SizedBox(height: DashboardLayoutTokens.gapOperational),
                    const _MagicCallPrimaryBlock(),
                    const SizedBox(height: DashboardLayoutTokens.gapOperational),
                    const PriorityCallSignalsCard(),
                    const SizedBox(height: DashboardLayoutTokens.gapOperational),
                    const SyncDelayedCustomersDashboardCard(),
                    const SizedBox(height: DashboardLayoutTokens.gapOperational),
                    const _QuickStatsCard(compact: true),
                    const SizedBox(height: DashboardLayoutTokens.gapOperational),
                    const _WeeklyGoalCard(),
                  ],
                ),
              ),
            ),
            // —— Layer 3: Insight — V1 odaklı modda kapatılır (piyasa/ticker/akademi ağırlığı)
            if (!lean) ...[
              const SliverToBoxAdapter(
                child: SizedBox(height: DashboardLayoutTokens.gapInsightSection),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DashboardLayoutTokens.horizontalPadding,
                  ),
                  child: _PipelineChampionCard(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: DashboardLayoutTokens.gapInsightSection),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DashboardLayoutTokens.horizontalPadding,
                  ),
                  child: DiscoveryPanel(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: DashboardLayoutTokens.gapInsightSection),
              ),
              const SliverToBoxAdapter(child: MasterTicker()),
              const SliverToBoxAdapter(
                child: SizedBox(height: DashboardLayoutTokens.gapInsightSection),
              ),
              const SliverToBoxAdapter(child: FinanceBar()),
              const SliverToBoxAdapter(
                child: SizedBox(height: DashboardLayoutTokens.gapInsightSection),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DashboardLayoutTokens.horizontalPadding,
                  ),
                  child: MarketPulsePanel(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: DashboardLayoutTokens.gapInsightSection),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DashboardLayoutTokens.horizontalPadding,
                  ),
                  child: _ConsultantAcademyCard(),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(height: summaryBottomPad + DesignTokens.space3),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Hero katmanı: selam + başlık + bildirim (tek odak alanı).
class _DashboardHeroHeader extends StatelessWidget {
  const _DashboardHeroHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: SessionAvatarButton(size: 40),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ext.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context).t('my_summary'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
              color: ext.textSecondary,
              size: 24,
            ),
            tooltip: AppLocalizations.of(context).t('notifications'),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

/// Danışmanın ekip ve yönetici bilgisi (teamId/managerId varsa).
class _ConsultantTeamLine extends ConsumerWidget {
  const _ConsultantTeamLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
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
                      color: ext.textTertiary,
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

/// Birincil: gerçek telefon; ikincil: Magic Call CRM; üçüncü: Tüm çağrılar.
class _MagicCallPrimaryBlock extends StatelessWidget {
  const _MagicCallPrimaryBlock();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PhoneCallPrimaryButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push(
              AppRouter.routeCall,
              extra: const {
                'startedFromScreen': 'consultant_dashboard',
              },
            );
          },
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            AnalyticsService.instance.logEvent(AnalyticsEvents.magicCallTap);
            context.push(
              AppRouter.routeCall,
              extra: const {
                'inAppCrmSession': true,
                'startedFromScreen': 'consultant_dashboard',
              },
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: ext.textPrimary,
            side: BorderSide(color: ext.borderSubtle),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
            ),
          ),
          icon: Icon(Icons.phone_in_talk_rounded, size: 18, color: ext.accent),
          label: const Text(
            'Magic Call (CRM)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  AnalyticsService.instance.logEvent(AnalyticsEvents.consultantCallsTap);
                  context.push(AppRouter.routeConsultantCalls);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ext.textPrimary,
                  side: BorderSide(color: ext.borderSubtle),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
                  ),
                ),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text(
                  'Tüm Çağrılarım',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneCallPrimaryButton extends StatelessWidget {
  const _PhoneCallPrimaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Semantics(
      button: true,
      label: 'Telefon ile ara',
      child: Material(
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        color: ext.accent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: DesignTokens.space4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_rounded, size: 22, color: ext.onBrand),
                const SizedBox(width: 10),
                Text(
                  'Telefon ile ara',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ext.onBrand,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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

/// Bugünkü hızlı KPI şeridi: çağrı, görev, pipeline.
class _TodayKpiRow extends ConsumerWidget {
  const _TodayKpiRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final textStyleLabel = TextStyle(
      color: ext.textSecondary,
      fontSize: DesignTokens.fontSizeXs,
    );
    final textStyleValue = TextStyle(
      color: ext.textPrimary,
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
    final ext = AppThemeExtension.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: DashboardLayoutTokens.minHeightKpi),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ext.accent),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  value,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                  borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: ext.accent, size: 22),
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
                HapticFeedback.lightImpact();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: ext.surface,
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
                              Icon(Icons.school_rounded, color: ext.accent, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'İtiraz karşılama – “Fiyat yüksek”',
                                  style: TextStyle(
                                    color: ext.textPrimary,
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
                            style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“Anlıyorum; bütçenizi zorlamadan size uygun seçenekleri birlikte netleştirelim.”',
                            style: TextStyle(color: ext.textSecondary, fontSize: 13, height: 1.45),
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            'Adım adım',
                            style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1) Empati: Müşterinin endişesini tekrar et; savunmaya geçme.\n\n'
                            '2) Çerçevele: Aynı bölgede son dönem kapanan örnekleri (m² fiyatı) kısaca paylaş.\n\n'
                            '3) Alternatif sun: Daha küçük metrekare veya komşu mahallede 1–2 seçenek öner.\n\n'
                            '4) Sonraki adım: “Yarın aynı saatte iki ilanı yerinde gösterebilir miyim?” diye net randevu iste.',
                            style: TextStyle(color: ext.textTertiary, fontSize: 12, height: 1.5),
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
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                              label: const Text('Magic Call ile uygula'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ext.accent,
                                foregroundColor: ext.onBrand,
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

class _WeeklyGoalCard extends ConsumerWidget {
  const _WeeklyGoalCard();

  static const int weeklyGoal = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final uid = ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return StreamBuilder<int>(
      stream: FirestoreService.agentWeeklyCallCountStream(uid),
      builder: (context, snap) {
        final current = snap.data ?? 0;
        final progress = weeklyGoal > 0 ? (current / weeklyGoal).clamp(0.0, 1.0) : 0.0;
        return Container(
          constraints: const BoxConstraints(minHeight: DashboardLayoutTokens.minHeightOperationalCard),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: 10),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
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
                      style: TextStyle(color: ext.textSecondary, fontSize: DesignTokens.fontSizeSm),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$current / $weeklyGoal çağrı',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
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
      },
    );
  }
}

class _PipelineChampionCard extends StatelessWidget {
  const _PipelineChampionCard();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRouter.routePipeline);
        },
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
        child: Container(
          constraints: const BoxConstraints(minHeight: DashboardLayoutTokens.minHeightInsightCard),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space4),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
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
                      'Pipeline',
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
                      'Satış hunisi · Aşamaları yönet',
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

class _QuickStatsCard extends ConsumerWidget {
  const _QuickStatsCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    final ext = AppThemeExtension.of(context);
    final count = resurrectionAsync.valueOrNull?.length ?? 0;
    final isLoading = resurrectionAsync.isLoading;
    final pad = compact ? DesignTokens.space4 : DesignTokens.space5;
    final iconBox = compact ? DesignTokens.space2 : DesignTokens.space3;
    final iconSize = compact ? 20.0 : 24.0;
    return RepaintBoundary(
      child: Container(
      constraints: BoxConstraints(
        minHeight: compact ? DashboardLayoutTokens.minHeightOperationalCard : DashboardLayoutTokens.minHeightInsightCard,
      ),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
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
                  borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
                ),
                child: Icon(
                  Icons.replay_rounded,
                  color: ext.accent,
                  size: iconSize,
                ),
              ),
              SizedBox(width: compact ? DesignTokens.space3 : DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takip listesi',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? DesignTokens.fontSizeSm : DesignTokens.fontSizeMd,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isLoading)
                      Text(
                        'Takip listesi yükleniyor...',
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        count == 0
                            ? 'Şu an takip edilecek lead yok'
                            : '$count lead takip bekliyor',
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
              if (count > 0)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: ext.accent,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRouter.routeResurrection);
                  },
                  child: const Text('Görüntüle'),
                ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Magic Call ile aradığın müşterilerin özeti otomatik kaydedilir; '
              'takip sekmesinden sessiz kalan lead\'lere ulaşabilirsin.',
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: DesignTokens.fontSizeXs,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Sessiz kalan lead\'ler için yeniden kazanım.',
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
    );
  }
}
