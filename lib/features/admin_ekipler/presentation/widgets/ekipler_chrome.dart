import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/admin_ekipler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_team_filter.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PremiumEkiplerHeader extends StatelessWidget {
  const PremiumEkiplerHeader({super.key, this.actions = const []});

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
              _EkiplerHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ekipler',
                        maxLines: 1,
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
                        'Takım yapısı ve operasyon dengesi',
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
              'Doğrulama: ekip kayıtları gerçek Firestore verisinden gelir; ofis baskı sinyalleri yalnızca mevcut ofis özetiyle gösterilir; ekip bazlı KPI uydurulmaz.',
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

class _EkiplerHeaderEmblem extends StatelessWidget {
  const _EkiplerHeaderEmblem({required this.size, required this.pad});

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

class PremiumEkiplerHealthStrip extends StatelessWidget {
  const PremiumEkiplerHealthStrip({super.key, required this.strip});

  final EkiplerHealthStrip strip;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    final cells = <(String, String, Color)>[
      (strip.activeTeams.toString(), 'Aktif ekip', ext.success),
      (strip.totalConsultants.toString(), 'Danışman', ext.accent),
      (strip.interventionTeams.toString(), 'Müdahale', ext.warning),
      (strip.unassignedConsultants.toString(), 'Atanmamış', ext.textSecondary),
      if (strip.hasOfficeSignals) ...[
        (strip.officeOpenTasks.toString(), 'Açık iş', ext.warning),
        (strip.officeFollowUpQueue.toString(), 'Takip', ext.info),
        if (strip.officeMissedCalls > 0)
          (strip.officeMissedCalls.toString(), 'Kaçırılan', ext.danger),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkiplerTokens.horizontal,
        AdminEkiplerTokens.chromeGap / 2,
        AdminEkiplerTokens.horizontal,
        AdminEkiplerTokens.chromeGap,
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

class EkiplerCompactSearch extends StatelessWidget {
  const EkiplerCompactSearch({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkiplerTokens.horizontal,
        0,
        AdminEkiplerTokens.horizontal,
        AdminEkiplerTokens.moduleGap,
      ),
      child: SizedBox(
        height: AdminEkiplerTokens.searchHeight,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: AdminEkiplerTokens.rowMetaSize,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminEkiplerTokens.rowMetaSize,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: ext.textTertiary,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            filled: true,
            fillColor: ext.surfaceElevated.withValues(alpha: 0.55),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.border.withValues(alpha: 0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.border.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.65)),
            ),
          ),
        ),
      ),
    );
  }
}

class EkiplerFilterChips extends StatelessWidget {
  const EkiplerFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EkiplerTeamFilter selected;
  final ValueChanged<EkiplerTeamFilter> onSelected;

  static const _filters = <(EkiplerTeamFilter, String)>[
    (EkiplerTeamFilter.all, 'Tümü'),
    (EkiplerTeamFilter.active, 'Aktif'),
    (EkiplerTeamFilter.intervention, 'Müdahale'),
    (EkiplerTeamFilter.emptyOrPressure, 'Boş/Baskı'),
    (EkiplerTeamFilter.unassigned, 'Atanmamış'),
    (EkiplerTeamFilter.detailed, 'Detaylı'),
    (EkiplerTeamFilter.silent, 'Sessiz'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AdminEkiplerTokens.filterChipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminEkiplerTokens.horizontal,
            ),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final (filter, label) = _filters[index];
              final active = selected == filter;
              return FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: AdminEkiplerTokens.rowChipSize,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? ext.accent : ext.textSecondary,
                  ),
                ),
                selected: active,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                side: BorderSide(
                  color: active
                      ? ext.accent.withValues(alpha: 0.45)
                      : ext.border.withValues(alpha: 0.35),
                ),
                backgroundColor: ext.surfaceElevated.withValues(alpha: 0.45),
                selectedColor: ext.accent.withValues(alpha: 0.12),
                onSelected: (_) => onSelected(filter),
              );
            },
          ),
        ),
        const SizedBox(height: AdminEkiplerTokens.moduleGap),
      ],
    );
  }
}

class EkiplerQuickRouteRow extends StatelessWidget {
  const EkiplerQuickRouteRow({
    super.key,
    required this.onKadro,
    required this.onReports,
    this.onCommandCenter,
    this.onWarRoom,
  });

  final VoidCallback onKadro;
  final VoidCallback onReports;
  final VoidCallback? onCommandCenter;
  final VoidCallback? onWarRoom;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.people_alt_outlined, label: 'Kadro', onTap: onKadro),
      (icon: Icons.analytics_outlined, label: 'Raporlar', onTap: onReports),
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
        AdminEkiplerTokens.horizontal,
        0,
        AdminEkiplerTokens.horizontal,
        AdminEkiplerTokens.moduleGap,
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
                  fontSize: AdminEkiplerTokens.rowChipSize,
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

class EkiplerSectionHeader extends StatelessWidget {
  const EkiplerSectionHeader({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkiplerTokens.horizontal,
        AdminEkiplerTokens.sectionGap,
        AdminEkiplerTokens.horizontal,
        AdminEkiplerTokens.moduleGap,
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
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
