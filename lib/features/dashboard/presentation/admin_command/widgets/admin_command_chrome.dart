import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PremiumAdminCommandHeader extends StatelessWidget {
  const PremiumAdminCommandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.showHonestyNote = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showHonestyNote;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
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
              _AdminHeaderEmblemAnchor(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                        subtitle,
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
              _AdminHeaderControlRail(
                metrics: m,
                dateLabel: today,
                actions: actions,
              ),
            ],
          ),
          if (showHonestyNote) ...[
            SizedBox(height: m.honestyTopGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: ext.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ext.info.withValues(alpha: 0.36)),
              ),
              child: Text(
                'Doğrulama notu: yalnızca gerçek ofis verisi gösterilir; tahmin veya sahte KPI yok.',
                style: TextStyle(
                  color: ext.textSecondary.withValues(alpha: 0.94),
                  fontSize: AdminCommandTokens.honestyNoteSize,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminHeaderEmblemAnchor extends StatelessWidget {
  const _AdminHeaderEmblemAnchor({
    required this.size,
    required this.pad,
  });

  final double size;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: ext.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BrandEmblem(
        variant: BrandEmblemVariant.mini,
        size: size,
      ),
    );
  }
}

class _AdminHeaderControlRail extends StatelessWidget {
  const _AdminHeaderControlRail({
    required this.metrics,
    required this.dateLabel,
    required this.actions,
  });

  final AdminCommandHeaderMetrics metrics;
  final String dateLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: ext.surfaceElevated.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ext.border.withValues(alpha: 0.38)),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: metrics.dateFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              height: 1,
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          SizedBox(height: metrics.controlRailGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                actions[i],
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class PremiumAdminHealthStrip extends StatelessWidget {
  const PremiumAdminHealthStrip({super.key, required this.summary});

  final AdminOfficeHealthSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final strip = AdminCommandTokens.adminStripTypography(context);
    final cells = <(String, String, Color)>[
      (summary.activeAdvisors.toString(), 'Aktif ekip', ext.accent),
      (summary.openTasks.toString(), 'Açık iş', ext.warning),
      (summary.liveCalls.toString(), 'Canlı görüşme', ext.success),
      (summary.officeAlerts.toString(), 'Uyarı', ext.danger),
      (summary.escalations.toString(), 'Taşıma', ext.warning),
      (summary.followUpQueue.toString(), 'Takip', ext.info),
      (summary.setupPending.toString(), 'Kurulum', ext.textSecondary),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminCommandTokens.horizontal,
        AdminCommandTokens.chromeGap / 2,
        AdminCommandTokens.horizontal,
        AdminCommandTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.72,
        child: SizedBox(
          height: AdminCommandTokens.summaryStripHeight,
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
                    adminLabelEmphasis: true,
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

/// Admin + War Room üst şerit hücresi — tek tipografi kaynağı.
class ExecutiveMetricStripCell extends StatelessWidget {
  const ExecutiveMetricStripCell({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.adminLabelEmphasis = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool adminLabelEmphasis;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final strip = adminLabelEmphasis
        ? AdminCommandTokens.adminStripTypography(context)
        : AdminCommandTokens.stripTypography(context);
    final labelColor = adminLabelEmphasis
        ? ext.textSecondary.withValues(alpha: 0.88)
        : ext.textTertiary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: strip.valueSize,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: labelColor,
            fontSize: strip.labelSize,
            fontWeight: FontWeight.w700,
            height: adminLabelEmphasis ? 1.08 : 1.05,
            letterSpacing: adminLabelEmphasis ? 0.05 : 0,
          ),
        ),
      ],
    );
  }
}

class PremiumAdminSectionLabel extends StatelessWidget {
  const PremiumAdminSectionLabel({
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
        AdminCommandTokens.horizontal,
        AdminCommandTokens.sectionGap,
        AdminCommandTokens.horizontal,
        AdminCommandTokens.moduleGap,
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminCommandTokens.sectionLabelSize,
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
                  fontSize: AdminCommandTokens.sectionSecondarySize,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumAdminIntelLines extends StatelessWidget {
  const PremiumAdminIntelLines({
    super.key,
    required this.recentLine,
    this.criticalLine,
  });

  final String? recentLine;
  final String? criticalLine;

  @override
  Widget build(BuildContext context) {
    if ((recentLine == null || recentLine!.trim().isEmpty) &&
        (criticalLine == null || criticalLine!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminCommandTokens.horizontal,
        0,
        AdminCommandTokens.horizontal,
        AdminCommandTokens.chromeGap,
      ),
      child: PremiumSurfaceCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminCommandTokens.intelCardPaddingH,
          vertical: AdminCommandTokens.intelCardPaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recentLine != null && recentLine!.trim().isNotEmpty)
              Text(
                recentLine!,
                style: AppTypography.meta(context).copyWith(
                  color: ext.textSecondary.withValues(alpha: 0.94),
                  fontSize: AdminCommandTokens.intelLineSize,
                  height: AdminCommandTokens.intelLineHeight,
                ),
              ),
            if (criticalLine != null && criticalLine!.trim().isNotEmpty) ...[
              if (recentLine != null && recentLine!.trim().isNotEmpty)
                const SizedBox(height: AdminCommandTokens.intelLineGap),
              Text(
                criticalLine!,
                style: AppTypography.meta(context).copyWith(
                  color: ext.warning.withValues(alpha: 0.96),
                  fontSize: AdminCommandTokens.intelLineSize,
                  fontWeight: FontWeight.w600,
                  height: AdminCommandTokens.intelCriticalLineHeight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
