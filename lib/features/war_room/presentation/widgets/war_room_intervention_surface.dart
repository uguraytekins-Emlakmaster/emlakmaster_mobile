import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_actions.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/resurrection_lead_topic_sheet.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/utils/war_room_intervention_model.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/war_room_tokens.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

abstract final class WarRoomInterventionActions {
  WarRoomInterventionActions._();

  static void handleLaneTap(BuildContext context, WarRoomPriorityLane lane) {
    AppFeedback.selectionClick();
    _navigate(context, lane.action);
  }

  static void handleRowTap(BuildContext context, WarRoomInterventionRow row) {
    AppFeedback.selectionClick();
    switch (row.action) {
      case WarRoomInterventionAction.customerDetail:
        final id = row.targetId;
        if (id != null && id.isNotEmpty) {
          context.push(
            AppRouter.routeCustomerDetail.replaceFirst(':id', id),
          );
          return;
        }
        _navigate(context, WarRoomInterventionAction.commandCenter);
      case WarRoomInterventionAction.followUpSheet:
        final item = row.followUpItem;
        if (item != null) {
          showResurrectionLeadTopicSheet(
            context,
            topicTitle: 'Müdahale · takip',
            item: item,
          );
          return;
        }
        if (row.targetId != null) {
          FollowUpListActions.openCustomer(
            context,
            ResurrectionQueueItem(
              customerId: row.targetId!,
              customerName: row.detail,
            ),
          );
          return;
        }
        _navigate(context, WarRoomInterventionAction.reportsTab);
      default:
        _navigate(context, row.action);
    }
  }

  static void _navigate(
    BuildContext context,
    WarRoomInterventionAction action,
  ) {
    switch (action) {
      case WarRoomInterventionAction.commandCenter:
        context.push(AppRouter.routeCommandCenter);
      case WarRoomInterventionAction.connectedAccounts:
        context.push(AppRouter.routeConnectedAccounts);
      case WarRoomInterventionAction.reportsTab:
        AdminShellNav.goToReportsTab(context);
      case WarRoomInterventionAction.followUpSheet:
        AdminShellNav.goToReportsTab(context);
      case WarRoomInterventionAction.customerDetail:
        context.push(AppRouter.routeCommandCenter);
    }
  }
}

class PremiumWarRoomHeader extends StatelessWidget {
  const PremiumWarRoomHeader({
    super.key,
    this.actions = const [],
    this.showHonestyNote = true,
  });

  final List<Widget> actions;
  final bool showHonestyNote;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final today = DateFormat('d MMM').format(DateTime.now());
    final m = AdminCommandTokens.headerMetrics(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.horizontal,
        m.topInset,
        m.horizontal,
        m.bottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(m.emblemPad),
                decoration: BoxDecoration(
                  color: ext.surfaceElevated.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ext.danger.withValues(alpha: 0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: ext.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.military_tech_rounded,
                  size: m.emblemSize,
                  color: premium.champagneGold,
                ),
              ),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savaş Odası',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.pageHeading(context).copyWith(
                          fontSize: m.titleSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          height: 1.04,
                        ),
                      ),
                      SizedBox(height: m.titleToSubtitleGap),
                      Text(
                        'Kritik operasyon ve müdahale merkezi',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta(context).copyWith(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: m.subtitleSize,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: m.titleGap - 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: ext.surfaceElevated.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: ext.border.withValues(alpha: 0.38)),
                    ),
                    child: Text(
                      today,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: m.dateFontSize,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    SizedBox(height: m.controlRailGap),
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ],
              ),
            ],
          ),
          if (showHonestyNote) ...[
            SizedBox(height: m.honestyTopGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: ext.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ext.info.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Doğrulama: yalnızca gerçek ofis sinyalleri; sahte alarm veya tahmin yok.',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: AdminCommandTokens.honestyNoteSize,
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WarRoomCrisisStrip extends StatelessWidget {
  const WarRoomCrisisStrip({super.key, required this.summary});

  final AdminOfficeHealthSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final strip = AdminCommandTokens.stripTypography(context);
    final cells = <(String, String, Color)>[
      if (summary.criticalEscalations > 0)
        (
          summary.criticalEscalations.toString(),
          'Kritik',
          ext.danger,
        ),
      if (summary.openTasks > 0)
        (summary.openTasks.toString(), 'Açık iş', ext.warning),
      if (summary.missedCalls > 0)
        (summary.missedCalls.toString(), 'Kaçırılan', ext.warning),
      if (summary.followUpQueue > 0)
        (summary.followUpQueue.toString(), 'Takip', ext.info),
      if (summary.setupPending > 0)
        (summary.setupPending.toString(), 'Kurulum', ext.textSecondary),
      if (summary.syncRisk > 0)
        (summary.syncRisk.toString(), 'Sync', ext.danger),
      if (summary.officeAlerts > 0)
        (summary.officeAlerts.toString(), 'Uyarı', ext.danger),
      if (summary.escalations > 0 && summary.criticalEscalations == 0)
        (summary.escalations.toString(), 'Taşıma', ext.warning),
    ];

    if (cells.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          WarRoomTokens.horizontal,
          WarRoomTokens.chromeGap,
          WarRoomTokens.horizontal,
          WarRoomTokens.chromeGap,
        ),
        child: ConsultantDashboardExecutiveSurface(
          ambientStrength: 0.55,
          child: SizedBox(
            height: WarRoomTokens.crisisStripHeight,
            child: Center(
              child: Text(
                'Kritik sinyal yok · ofis akışı izleniyor',
                style: AppTypography.meta(context).copyWith(
                  color: ext.textSecondary,
                  fontSize: AdminCommandTokens.intelLineSize,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WarRoomTokens.horizontal,
        WarRoomTokens.chromeGap,
        WarRoomTokens.horizontal,
        WarRoomTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        child: SizedBox(
          height: WarRoomTokens.crisisStripHeight,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: strip.dividerHeight,
                    color: ext.border.withValues(alpha: 0.28),
                  ),
                Expanded(
                  child: ExecutiveMetricStripCell(
                    value: cells[i].$1,
                    label: cells[i].$2,
                    color: cells[i].$3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WarRoomSectionLabel extends StatelessWidget {
  const WarRoomSectionLabel({
    super.key,
    required this.label,
    this.secondary,
  });

  final String label;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WarRoomTokens.horizontal,
        WarRoomTokens.sectionGap,
        WarRoomTokens.horizontal,
        WarRoomTokens.moduleGap,
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: WarRoomTokens.sectionLabelSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                secondary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.meta(context).copyWith(
                  color: ext.textTertiary.withValues(alpha: 0.85),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WarRoomPriorityLanes extends StatelessWidget {
  const WarRoomPriorityLanes({super.key, required this.lanes});

  final List<WarRoomPriorityLane> lanes;

  @override
  Widget build(BuildContext context) {
    if (lanes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: WarRoomTokens.horizontal),
        child: _QuietInterventionCard(
          message: 'Öncelik hattı sakin. Acil müdahale bekleyen kuyruk yok.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WarRoomTokens.horizontal),
      child: Column(
        children: [
          for (var i = 0; i < lanes.length; i++) ...[
            if (i > 0) const SizedBox(height: WarRoomTokens.moduleGap),
            RepaintBoundary(
              child: _PriorityLaneTile(lane: lanes[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityLaneTile extends StatelessWidget {
  const _PriorityLaneTile({required this.lane});

  final WarRoomPriorityLane lane;

  Color _tone(AppThemeExtension ext) => switch (lane.kind) {
        WarRoomLaneKind.overdueTasks => ext.warning,
        WarRoomLaneKind.followUpPressure => ext.accent,
        WarRoomLaneKind.missedCalls => ext.warning,
        WarRoomLaneKind.integration => ext.info,
        WarRoomLaneKind.alertsEscalation => ext.danger,
        WarRoomLaneKind.teamSignal => ext.warning,
      };

  IconData _icon() => switch (lane.kind) {
        WarRoomLaneKind.overdueTasks => Icons.pending_actions_rounded,
        WarRoomLaneKind.followUpPressure => Icons.schedule_rounded,
        WarRoomLaneKind.missedCalls => Icons.phone_missed_rounded,
        WarRoomLaneKind.integration => Icons.hub_outlined,
        WarRoomLaneKind.alertsEscalation => Icons.priority_high_rounded,
        WarRoomLaneKind.teamSignal => Icons.groups_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = _tone(ext);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => WarRoomInterventionActions.handleLaneTap(context, lane),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: WarRoomTokens.laneHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tone.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              Icon(_icon(), size: 20, color: tone),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lane.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: WarRoomTokens.laneTitleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      lane.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: WarRoomTokens.laneMetaSize,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${lane.count}',
                  style: TextStyle(
                    color: tone,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: ext.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class WarRoomInterventionList extends StatelessWidget {
  const WarRoomInterventionList({super.key, required this.rows});

  final List<WarRoomInterventionRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: WarRoomTokens.horizontal),
        child: _QuietInterventionCard(
          message:
              'Müdahale listesi boş. Gerçek uyarı veya taşıma oluştuğunda burada görünür.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WarRoomTokens.horizontal),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: WarRoomTokens.moduleGap),
            RepaintBoundary(
              child: _InterventionRowTile(row: rows[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterventionRowTile extends StatelessWidget {
  const _InterventionRowTile({required this.row});

  final WarRoomInterventionRow row;

  Color _severityTone(AppThemeExtension ext) {
    if (row.severityLabel == 'Kritik' || row.severityLabel == 'Sync') {
      return ext.danger;
    }
    if (row.severityLabel == 'Yüksek') return ext.warning;
    return ext.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = _severityTone(ext);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => WarRoomInterventionActions.handleRowTap(context, row),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ext.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ext.border.withValues(alpha: 0.32)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: WarRoomTokens.interventionRowHeight - 16,
            ),
            child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: WarRoomTokens.interventionTitleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${row.source} · ${row.detail}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: WarRoomTokens.interventionMetaSize,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  row.severityLabel,
                  style: TextStyle(
                    color: tone,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: ext.textTertiary),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class WarRoomSecondaryRoutes extends StatelessWidget {
  const WarRoomSecondaryRoutes({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tiles = <({IconData icon, String title, String subtitle, VoidCallback onTap})>[
      (
        icon: Icons.phone_in_talk_rounded,
        title: ProductLabels.callCenter,
        subtitle: 'Kaçırılan ve canlı çağrılar',
        onTap: () {
          AppFeedback.selectionClick();
          context.push(AppRouter.routeCommandCenter);
        },
      ),
      (
        icon: Icons.analytics_rounded,
        title: ProductLabels.reports,
        subtitle: 'Kadro ve performans',
        onTap: () {
          AppFeedback.selectionClick();
          AdminShellNav.goToReportsTab(context);
        },
      ),
      (
        icon: Icons.hub_outlined,
        title: 'Entegrasyonlar',
        subtitle: 'Kanal kurulum ve sync',
        onTap: () {
          AppFeedback.selectionClick();
          context.push(AppRouter.routeConnectedAccounts);
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WarRoomTokens.horizontal),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: WarRoomTokens.moduleGap),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: tiles[i].onTap,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  height: WarRoomTokens.routeTileHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ext.surface.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ext.border.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    children: [
                      Icon(tiles[i].icon, size: 20, color: ext.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tiles[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              tiles[i].subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: ext.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WarRoomPartialState extends StatelessWidget {
  const WarRoomPartialState({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.all(WarRoomTokens.horizontal),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 36, color: ext.textTertiary),
          const SizedBox(height: 10),
          Text(
            'Operasyon verisi şu an alınamadı',
            textAlign: TextAlign.center,
            style: AppTypography.body(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bağlantıyı kontrol edip yeniden deneyin. Sahte durum gösterilmez.',
            textAlign: TextAlign.center,
            style: AppTypography.meta(context).copyWith(
              color: ext.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Yeniden dene'),
          ),
        ],
      ),
    );
  }
}

class WarRoomLoadingSkeleton extends StatelessWidget {
  const WarRoomLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WarRoomTokens.horizontal),
          child: Container(
            height: WarRoomTokens.crisisStripHeight,
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WarRoomTokens.horizontal,
              0,
              WarRoomTokens.horizontal,
              WarRoomTokens.moduleGap,
            ),
            child: Container(
              height: WarRoomTokens.laneHeight,
              decoration: BoxDecoration(
                color: ext.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuietInterventionCard extends StatelessWidget {
  const _QuietInterventionCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 18, color: ext.success.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.meta(context).copyWith(
                color: ext.textSecondary,
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
