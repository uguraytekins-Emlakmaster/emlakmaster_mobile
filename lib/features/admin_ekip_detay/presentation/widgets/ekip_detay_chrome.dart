import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PremiumEkipDetayHeader extends StatelessWidget {
  const PremiumEkipDetayHeader({
    super.key,
    required this.teamName,
    this.managerLine,
    this.actions = const [],
  });

  final String teamName;
  final String? managerLine;
  final List<Widget> actions;

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
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: PremiumNavLeading(),
              ),
              SizedBox(width: m.titleGap - 4),
              _HeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
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
                        'Ekip detayı ve operasyon görünümü',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta(context).copyWith(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: m.subtitleSize,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                        ),
                      ),
                      if (managerLine != null && managerLine!.isNotEmpty) ...[
                        SizedBox(height: m.titleToSubtitleGap * 0.6),
                        Text(
                          managerLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: AdminEkipDetayTokens.rowMetaSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
              'Doğrulama: ekip üyeleri gerçek roster kayıtlarından gelir; ofis baskı sinyalleri yalnızca ofis özeti düzeyindedir; ekip bazlı performans skoru uydurulmaz.',
              style: TextStyle(
                color: ext.textSecondary.withValues(alpha: 0.94),
                fontSize: AdminCommandTokens.honestyNoteSize,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderEmblem extends StatelessWidget {
  const _HeaderEmblem({required this.size, required this.pad});

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
      ),
      child: BrandEmblem(variant: BrandEmblemVariant.mini, size: size),
    );
  }
}

class PremiumEkipDetayHealthStrip extends StatelessWidget {
  const PremiumEkipDetayHealthStrip({super.key, required this.strip});

  final EkipDetayHealthStrip strip;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    final cells = <(String, String, Color)>[
      (strip.totalMembers.toString(), 'Üye', ext.accent),
      (strip.activeMembers.toString(), 'Aktif', ext.success),
      (strip.interventionMembers.toString(), 'Müdahale', ext.warning),
      if (strip.hasOfficeSignals) ...[
        (strip.officeOpenTasks.toString(), 'Açık iş', ext.warning),
        (strip.officeFollowUpQueue.toString(), 'Takip', ext.info),
        if (strip.officeMissedCalls > 0)
          (strip.officeMissedCalls.toString(), 'Kaçırılan', ext.danger),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.chromeGap / 2,
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.68,
        child: SizedBox(
          height: AdminCommandTokens.summaryStripHeight,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: typography.dividerHeight,
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

class EkipDetayQuickRouteRow extends StatelessWidget {
  const EkipDetayQuickRouteRow({
    super.key,
    required this.onKadro,
    required this.onTeams,
    required this.onReports,
    this.onAddMember,
    this.onCommandCenter,
    this.onWarRoom,
  });

  final VoidCallback onKadro;
  final VoidCallback onTeams;
  final VoidCallback onReports;
  final VoidCallback? onAddMember;
  final VoidCallback? onCommandCenter;
  final VoidCallback? onWarRoom;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.people_alt_outlined, label: 'Kadro', onTap: onKadro),
      (icon: Icons.groups_outlined, label: 'Ekipler', onTap: onTeams),
      (icon: Icons.analytics_outlined, label: 'Raporlar', onTap: onReports),
      if (onAddMember != null)
        (
          icon: Icons.person_add_outlined,
          label: 'Danışman ata',
          onTap: onAddMember!,
        ),
      if (onCommandCenter != null)
        (
          icon: Icons.phone_in_talk_outlined,
          label: 'Çağrı merkezi',
          onTap: onCommandCenter!,
        ),
      if (onWarRoom != null)
        (
          icon: Icons.military_tech_outlined,
          label: 'Savaş odası',
          onTap: onWarRoom!,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkipDetayTokens.horizontal,
        0,
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.moduleGap,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final item in items)
            ActionChip(
              avatar: Icon(item.icon, size: 16, color: ext.accent),
              label: Text(
                item.label,
                style: TextStyle(
                  fontSize: AdminEkipDetayTokens.rowChipSize,
                  color: ext.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: ext.surfaceElevated.withValues(alpha: 0.45),
              side: BorderSide(color: ext.border.withValues(alpha: 0.3)),
              onPressed: item.onTap,
            ),
        ],
      ),
    );
  }
}

String turkishSectionUpper(String input) {
  final buf = StringBuffer();
  for (final code in input.runes) {
    final c = String.fromCharCode(code);
    buf.write(
      switch (c) {
        'i' => 'İ',
        'ı' => 'I',
        'ş' => 'Ş',
        'ğ' => 'Ğ',
        'ü' => 'Ü',
        'ö' => 'Ö',
        'ç' => 'Ç',
        _ => c.toUpperCase(),
      },
    );
  }
  return buf.toString();
}

class EkipDetaySectionHeader extends StatelessWidget {
  const EkipDetaySectionHeader({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.sectionGap,
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.moduleGap,
      ),
      child: Row(
        children: [
          Text(
            turkishSectionUpper(title),
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminCommandTokens.sectionLabelSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                color: ext.textTertiary.withValues(alpha: 0.85),
                fontSize: AdminCommandTokens.sectionSecondarySize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EkipDetayOfficeNote extends StatelessWidget {
  const EkipDetayOfficeNote({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkipDetayTokens.horizontal,
        0,
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.moduleGap,
      ),
      child: Text(
        'Ofis sinyalleri (Açık iş · Takip · Kaçırılan) tüm ofis düzeyindedir; bu ekibe özel KPI değildir.',
        style: TextStyle(
          color: ext.textTertiary,
          fontSize: AdminEkipDetayTokens.rowChipSize,
          height: 1.2,
        ),
      ),
    );
  }
}
