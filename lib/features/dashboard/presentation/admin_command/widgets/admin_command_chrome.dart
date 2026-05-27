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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminCommandTokens.horizontal,
        AdminCommandTokens.topInset + 4,
        AdminCommandTokens.horizontal,
        AdminCommandTokens.headerBottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: AdminCommandTokens.headerEmblemSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.pageHeading(context).copyWith(
                        fontSize: AdminCommandTokens.headerTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.meta(context).copyWith(
                        color: ext.textSecondary.withValues(alpha: 0.88),
                        fontSize: AdminCommandTokens.headerSubtitleSize,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ext.surfaceElevated.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ext.border.withValues(alpha: 0.35)),
                ),
                child: Text(
                  today,
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ...actions,
            ],
          ),
          if (showHonestyNote) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ext.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ext.info.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Doğrulama notu: yalnızca gerçek ofis verisi gösterilir; tahmin veya sahte KPI yok.',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumAdminHealthStrip extends StatelessWidget {
  const PremiumAdminHealthStrip({super.key, required this.summary});

  final AdminOfficeHealthSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
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
                    height: 28,
                    color: ext.border.withValues(alpha: 0.28),
                  ),
                Expanded(
                  child: _HealthCell(
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

class _HealthCell extends StatelessWidget {
  const _HealthCell({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ext.textTertiary,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            height: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recentLine != null && recentLine!.trim().isNotEmpty)
              Text(
                recentLine!,
                style: AppTypography.meta(context).copyWith(
                  color: ext.textSecondary,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            if (criticalLine != null && criticalLine!.trim().isNotEmpty) ...[
              if (recentLine != null && recentLine!.trim().isNotEmpty)
                const SizedBox(height: 4),
              Text(
                criticalLine!,
                style: AppTypography.meta(context).copyWith(
                  color: ext.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
