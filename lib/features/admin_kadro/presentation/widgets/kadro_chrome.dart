import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_snapshot.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PremiumKadroHeader extends StatelessWidget {
  const PremiumKadroHeader({
    super.key,
    this.actions = const [],
  });

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
              _KadroHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kadro',
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
                        'Ekip durumu ve danışman yönetimi',
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
              'Doğrulama: liste gerçek kullanıcı kayıtlarından gelir; danışman KPI\'ları yalnızca mevcut ofis sinyalleriyle gösterilir.',
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

class _KadroHeaderEmblem extends StatelessWidget {
  const _KadroHeaderEmblem({required this.size, required this.pad});

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

class PremiumKadroHealthStrip extends StatelessWidget {
  const PremiumKadroHealthStrip({super.key, required this.strip});

  final KadroHealthStrip strip;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    final cells = <(String, String, Color)>[
      (strip.activeConsultants.toString(), 'Aktif', ext.success),
      (strip.needsIntervention.toString(), 'Müdahale', ext.warning),
      (strip.teamCount.toString(), 'Takım', ext.accent),
      if (strip.hasOfficeSignals) ...[
        (strip.officeOpenTasks.toString(), 'Açık iş', ext.warning),
        (strip.officeFollowUpQueue.toString(), 'Takip', ext.info),
        if (strip.officeMissedCalls > 0)
          (strip.officeMissedCalls.toString(), 'Kaçırılan', ext.danger),
        if (strip.officeEscalations > 0)
          (strip.officeEscalations.toString(), 'Taşıma', ext.danger),
      ] else ...[
        (strip.unassignedConsultants.toString(), 'Atanmamış', ext.textSecondary),
        if (strip.inactiveConsultants > 0)
          (strip.inactiveConsultants.toString(), 'Pasif', ext.textTertiary),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminKadroTokens.horizontal,
        AdminKadroTokens.chromeGap / 2,
        AdminKadroTokens.horizontal,
        AdminKadroTokens.chromeGap,
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

class KadroCompactSearch extends StatelessWidget {
  const KadroCompactSearch({
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
        AdminKadroTokens.horizontal,
        0,
        AdminKadroTokens.horizontal,
        AdminKadroTokens.moduleGap,
      ),
      child: SizedBox(
        height: AdminKadroTokens.searchHeight,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: AdminKadroTokens.rowMetaSize,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminKadroTokens.rowMetaSize,
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

class KadroFilterChips extends StatelessWidget {
  const KadroFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.teamFilterId,
    this.teams = const [],
    this.onTeamSelected,
  });

  final KadroRosterFilter selected;
  final ValueChanged<KadroRosterFilter> onSelected;
  final String? teamFilterId;
  final List<({String id, String name})> teams;
  final ValueChanged<String?>? onTeamSelected;

  static const _filters = <(KadroRosterFilter, String)>[
    (KadroRosterFilter.all, 'Tümü'),
    (KadroRosterFilter.active, 'Aktif'),
    (KadroRosterFilter.intervention, 'Müdahale'),
    (KadroRosterFilter.silent, 'Sessiz'),
    (KadroRosterFilter.byTeam, 'Takım'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AdminKadroTokens.filterChipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminKadroTokens.horizontal,
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
                    fontSize: AdminKadroTokens.rowChipSize,
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
        if (selected == KadroRosterFilter.byTeam && teams.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: AdminKadroTokens.filterChipHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AdminKadroTokens.horizontal,
              ),
              itemCount: teams.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final active = teamFilterId == null;
                  return FilterChip(
                    label: Text(
                      'Tüm takımlar',
                      style: TextStyle(
                        fontSize: AdminKadroTokens.rowChipSize,
                        color: active ? ext.accent : ext.textSecondary,
                      ),
                    ),
                    selected: active,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => onTeamSelected?.call(null),
                  );
                }
                final team = teams[index - 1];
                final active = teamFilterId == team.id;
                return FilterChip(
                  label: Text(
                    team.name,
                    style: TextStyle(
                      fontSize: AdminKadroTokens.rowChipSize,
                      color: active ? ext.accent : ext.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: active,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onTeamSelected?.call(team.id),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AdminKadroTokens.moduleGap),
      ],
    );
  }
}

class KadroQuickRouteRow extends StatelessWidget {
  const KadroQuickRouteRow({
    super.key,
    required this.onTeams,
    required this.onReports,
    this.onCommandCenter,
    this.onWarRoom,
  });

  final VoidCallback onTeams;
  final VoidCallback onReports;
  final VoidCallback? onCommandCenter;
  final VoidCallback? onWarRoom;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.groups_rounded, label: 'Ekipler', onTap: onTeams),
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
        AdminKadroTokens.horizontal,
        0,
        AdminKadroTokens.horizontal,
        AdminKadroTokens.moduleGap,
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
                  fontSize: AdminKadroTokens.rowChipSize,
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

class KadroSectionHeader extends StatelessWidget {
  const KadroSectionHeader({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminKadroTokens.horizontal,
        AdminKadroTokens.sectionGap,
        AdminKadroTokens.horizontal,
        AdminKadroTokens.moduleGap,
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
