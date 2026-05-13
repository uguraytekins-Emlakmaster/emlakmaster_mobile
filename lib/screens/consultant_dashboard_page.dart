import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_dashboard_reminder.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/ai_usage_indicator.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/sync_delayed_customers_dashboard_card.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/consultant_performance_strip.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_intelligence_dashboard_section.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/execution_reminders_card.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/widgets/priority_call_signals_card.dart';
import 'package:emlakmaster_mobile/features/deal_discovery/presentation/widgets/discovery_panel.dart';
import 'package:emlakmaster_mobile/features/market_heatmap/presentation/widgets/market_pulse_panel.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Danışman paneli — [DashboardPage] ile aynı tasarım sistemi: **Hero** → **Operational** → **Insight** ([DashboardLayoutTokens]).
class ConsultantDashboardPage extends ConsumerWidget {
  const ConsultantDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final ext = AppThemeExtension.of(context);
      final lean = ref.watch(
        featureFlagsProvider.select(
          (a) => a.valueOrNull?[AppConstants.keyV1LeanProduct] ?? true,
        ),
      );
      final summaryBottomPad =
          DashboardLayoutTokens.shellScrollBottomPadding(context);
      final user = ref.watch(currentUserProvider.select((v) => v.valueOrNull));
      final hour = DateTime.now().hour;
      final salutation =
          hour < 12 ? 'Günaydın' : (hour < 18 ? 'İyi günler' : 'İyi akşamlar');
      final String firstName;
      final dn = user?.displayName?.trim();
      if (dn != null && dn.isNotEmpty) {
        firstName = dn.split(RegExp(r'\s+')).first;
      } else if (user?.email != null) {
        firstName = user!.email!.split('@').first;
      } else {
        firstName = 'Danışman';
      }
      final greeting = '$salutation, $firstName';

      return Material(
        color: ext.background,
        child: SafeArea(
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
                        _DashboardHeroHeader(
                          greeting: greeting,
                          tagline:
                              'Bugünkü oyun alanın — çağrı, müşteri ve momentum tek ekranda.',
                        ),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapHeroToOperational),
                        const PostCallCaptureDashboardReminder(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperationalTight),
                        const _ConsultantTeamLine(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        const _ConsultantActionAnchor(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        Text(
                          'Hızlı durum',
                          style: AppTypography.sectionLabel(context),
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        const _TodayKpiRow(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperationalTight),
                        const AiUsageIndicator(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperationalTight),
                        const ConsultantPerformanceStrip(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        Text(
                          'Fırsat ve gelir motoru',
                          style: AppTypography.sectionLabel(context),
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        const RevenueIntelligenceDashboardSection(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperationalTight),
                        const ExecutionRemindersCard(
                            surface: ExecutionReminderSurface.consultant),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        const PriorityCallSignalsCard(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        const SyncDelayedCustomersDashboardCard(),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        const _QuickStatsCard(compact: true),
                        const SizedBox(
                            height: DashboardLayoutTokens.gapOperational),
                        const _WeeklyGoalCard(),
                      ],
                    ),
                  ),
                ),
                // —— Layer 3: Insight — V1 odaklı modda kapatılır (piyasa/ticker/akademi ağırlığı)
                if (!lean) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(
                        height: DashboardLayoutTokens.gapInsightSection),
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
                    child: SizedBox(
                        height: DashboardLayoutTokens.gapInsightSection),
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
                    child: SizedBox(
                        height: DashboardLayoutTokens.gapInsightSection),
                  ),
                  const SliverToBoxAdapter(child: MasterTicker()),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                        height: DashboardLayoutTokens.gapInsightSection),
                  ),
                  const SliverToBoxAdapter(child: FinanceBar()),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                        height: DashboardLayoutTokens.gapInsightSection),
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
                    child: SizedBox(
                        height: DashboardLayoutTokens.gapInsightSection),
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
                  child:
                      SizedBox(height: summaryBottomPad + DesignTokens.space3),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e('ConsultantDashboardPage build', e, st);
      final ext = AppThemeExtension.of(context);
      return Material(
        color: ext.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: ext.accent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Danisman paneli hazirlanamadi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: DesignTokens.fontSizeLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ekran yuklenirken bir sorun olustu. Uygulama kabugu aktif; ana sekmeler kullanilmaya devam edebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                      height: 1.45,
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
}

/// Hero katmanı: selam + başlık + günlük bağlam + bildirim.
class _DashboardHeroHeader extends StatelessWidget {
  const _DashboardHeroHeader({
    required this.greeting,
    required this.tagline,
  });

  final String greeting;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: SessionAvatarButton(size: 44),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTypography.pageEyebrow(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.space1),
              Text(
                AppLocalizations.of(context).t('my_summary'),
                style: AppTypography.pageHeading(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                tagline,
                style: AppTypography.meta(context).copyWith(
                  color: ext.textTertiary,
                  height: 1.35,
                ),
                maxLines: 3,
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
                final managerName =
                    managerSnap.data?.name ?? managerSnap.data?.email ?? '—';
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

/// Danışman panelinin aksiyon sabiti: birincil arama + ikincil CRM / geçmiş.
class _ConsultantActionAnchor extends StatelessWidget {
  const _ConsultantActionAnchor();

  static const double _narrowActionBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final radius = BorderRadius.circular(DashboardLayoutTokens.radiusCardM);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: ext.surfaceElevated,
        border: Border.all(color: ext.border.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ext.accent.withValues(alpha: 0.85),
                      ext.accent.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                DesignTokens.space5,
                DesignTokens.space4,
                DesignTokens.space4,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < _narrowActionBreakpoint;
                  final secondaryBorder =
                      BorderSide(color: ext.border.withValues(alpha: 0.72));
                  final secondaryShape = RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        DashboardLayoutTokens.radiusCardS),
                  );
                  ButtonStyle secondaryStyle() => OutlinedButton.styleFrom(
                        foregroundColor: ext.textPrimary,
                        side: secondaryBorder,
                        minimumSize: const Size(0, 48),
                        padding: EdgeInsets.symmetric(
                          vertical: narrow ? 14 : 12,
                          horizontal: narrow ? 10 : 8,
                        ),
                        shape: secondaryShape,
                        visualDensity: VisualDensity.standard,
                      );
                  final secondaryChildren = [
                    Semantics(
                      button: true,
                      label: 'Akıllı görüşme ile ara',
                      child: Tooltip(
                        message: 'Uygulama içi kayıt oturumu',
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            AnalyticsService.instance
                                .logEvent(AnalyticsEvents.magicCallTap);
                            context.push(
                              AppRouter.routeCall,
                              extra: const {
                                'inAppCrmSession': true,
                                'startedFromScreen': 'consultant_dashboard',
                              },
                            );
                          },
                          style: secondaryStyle(),
                          icon: Icon(Icons.phone_in_talk_rounded,
                              size: 22, color: ext.accent),
                          label: Text(
                            'Akıllı Görüşme',
                            style: AppTypography.secondaryButton(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (!narrow) const SizedBox(width: DesignTokens.space2),
                    if (narrow) const SizedBox(height: DesignTokens.space2),
                    Semantics(
                      button: true,
                      label: 'Tüm çağrılarımı aç',
                      child: Tooltip(
                        message: 'Kayıtlı çağrı geçmişi',
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            AnalyticsService.instance
                                .logEvent(AnalyticsEvents.consultantCallsTap);
                            context.push(AppRouter.routeConsultantCalls);
                          },
                          style: secondaryStyle(),
                          icon: Icon(Icons.history_rounded,
                              size: 22, color: ext.textSecondary),
                          label: Text(
                            narrow ? 'Çağrılar' : 'Çağrılarım',
                            style: AppTypography.secondaryButton(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bugünün birinci adımı',
                        style: AppTypography.sectionLabel(context),
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        narrow
                            ? 'Bir görüşme günü açar; özet ve görevler ardından akışa düşer.'
                            : 'Tek bir görüşme günü açar; özet ve görevler hemen ardından akışa düşer.',
                        style: AppTypography.meta(context).copyWith(
                          color: ext.textTertiary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
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
                      const SizedBox(height: DesignTokens.space3),
                      if (narrow)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: secondaryChildren,
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: secondaryChildren[0]),
                            secondaryChildren[1],
                            Expanded(child: secondaryChildren[2]),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneCallPrimaryButton extends StatelessWidget {
  const _PhoneCallPrimaryButton({required this.onPressed});

  final VoidCallback onPressed;

  static const String _subtitleFull =
      'Kayıtlı arama; özet ve görevler akışta seni bekler';
  static const String _subtitleShort = 'Kayıtlı arama; özet ve görevler hazır';

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final ts = MediaQuery.textScalerOf(context);
    final textScaleRatio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return Semantics(
      button: true,
      label:
          'Telefon ile ara. Kayıtlı aramada özet ve görevler otomatik hazırlanır.',
      child: Material(
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
        color: ext.accent,
        child: InkWell(
          onTap: onPressed,
          borderRadius:
              BorderRadius.circular(DashboardLayoutTokens.radiusCardS),
          splashColor: ext.onBrand.withValues(alpha: 0.14),
          highlightColor: ext.onBrand.withValues(alpha: 0.08),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useShortSubtitle =
                  constraints.maxWidth < 304 || textScaleRatio > 1.18;
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: DesignTokens.space4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_rounded,
                              size: 24, color: ext.onBrand),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Telefon ile ara',
                              style: AppTypography.primaryButton(context)
                                  .copyWith(color: ext.onBrand),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        useShortSubtitle ? _subtitleShort : _subtitleFull,
                        style: TextStyle(
                          color: ext.onBrand.withValues(alpha: 0.92),
                          fontSize: DesignTokens.fontSizeXs,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
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
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    void openCalls() {
      HapticFeedback.lightImpact();
      context.push(AppRouter.routeConsultantCalls);
    }

    void openTasks() {
      HapticFeedback.lightImpact();
      ref
          .read(mainShellShortcutProvider.notifier)
          .enqueue(MainShellShortcut.openTasksTab);
      context.go(AppRouter.routeHome);
    }

    void openPipeline() {
      HapticFeedback.lightImpact();
      context.push(AppRouter.routePipeline);
    }

    final textStyleLabel = TextStyle(
      color: ext.textSecondary,
      fontSize: DesignTokens.fontSizeSm,
      fontWeight: FontWeight.w600,
    );
    final textStyleValue = AppTypography.metricValue(context).copyWith(
      color: ext.textPrimary,
      fontSize: DesignTokens.fontSizeXl,
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
                onTap: openCalls,
                emphasized: true,
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
                onTap: openTasks,
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
                onTap: openPipeline,
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
    this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final radius = BorderRadius.circular(DashboardLayoutTokens.radiusCardS);
    final borderColor =
        emphasized ? ext.accent.withValues(alpha: 0.45) : ext.borderSubtle;
    final child = Container(
      constraints: BoxConstraints(
        minHeight: emphasized
            ? DashboardLayoutTokens.minHeightKpi + 4
            : DashboardLayoutTokens.minHeightKpi,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? DesignTokens.space3 + 1 : DesignTokens.space3,
        vertical: DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? ext.accent.withValues(alpha: 0.06)
            : ext.surfaceElevated,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: emphasized ? 20 : 18, color: ext.accent),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: emphasized
                      ? valueStyle.copyWith(
                          fontSize: DesignTokens.fontSizeXl + 2,
                          fontWeight: FontWeight.w800,
                        )
                      : valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.metricLabelGap),
                Text(label,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        splashColor: ext.accent.withValues(alpha: 0.12),
        child: child,
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
                HapticFeedback.lightImpact();
                showPremiumModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) => DraggableScrollableSheet(
                    initialChildSize: 0.55,
                    minChildSize: 0.35,
                    maxChildSize: 0.92,
                    expand: false,
                    builder: (_, scroll) => SingleChildScrollView(
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
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return StreamBuilder<int>(
      stream: FirestoreService.agentWeeklyCallCountStream(uid),
      builder: (context, snap) {
        final current = snap.data ?? 0;
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
                    width: compact ? DesignTokens.space3 : DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geri kazanım',
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
                          'Geri kazanım akışı yükleniyor...',
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
    );
  }
}
