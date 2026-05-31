import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/admin_uyelikler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String turkishUyelikSectionUpper(String label) {
  const map = {
    'i': 'İ',
    'ı': 'I',
    'ş': 'Ş',
    'ğ': 'Ğ',
    'ü': 'Ü',
    'ö': 'Ö',
    'ç': 'Ç',
  };
  return label
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        final first = w[0];
        final upper = map[first] ?? first.toUpperCase();
        return '$upper${w.substring(1)}';
      })
      .join(' ')
      .toUpperCase();
}

class PremiumUyeliklerHeader extends StatelessWidget {
  const PremiumUyeliklerHeader({
    super.key,
    this.actions = const [],
    this.coverageNote = '',
  });

  final List<Widget> actions;
  final String coverageNote;

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
              _UyelikHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Üyelikler / Davetler',
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
                        'Davet, onboarding ve katılım takibi',
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
              coverageNote.isNotEmpty
                  ? coverageNote
                  : 'Yalnızca gerçek davet ve üyelik kayıtları gösterilir; uydurma onboarding/lifecycle yok.',
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

class _UyelikHeaderEmblem extends StatelessWidget {
  const _UyelikHeaderEmblem({required this.size, required this.pad});

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

class PremiumUyeliklerSummaryStrip extends StatelessWidget {
  const PremiumUyeliklerSummaryStrip({super.key, required this.strip});

  final UyeliklerSummaryStrip strip;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    final cells = <(String, String, Color)>[
      if (strip.pendingInvites > 0)
        (strip.pendingInvites.toString(), 'Bekleyen', ext.info),
      if (strip.acceptedInvites > 0)
        (strip.acceptedInvites.toString(), 'Kabul', ext.success),
      if (strip.activeMembers > 0)
        (strip.activeMembers.toString(), 'Aktif üye', ext.accent),
      if (strip.expiredInvites > 0)
        (strip.expiredInvites.toString(), 'Süre doldu', ext.warning),
      if (strip.interventionCount > 0)
        (strip.interventionCount.toString(), 'Müdahale', ext.danger),
    ];

    if (cells.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AdminUyeliklerTokens.horizontal,
          AdminUyeliklerTokens.chromeGap / 2,
          AdminUyeliklerTokens.horizontal,
          AdminUyeliklerTokens.chromeGap,
        ),
        child: ConsultantDashboardExecutiveSurface(
          ambientStrength: 0.68,
          child: SizedBox(
            height: AdminCommandTokens.summaryStripHeight,
            child: Center(
              child: Text(
                strip.total > 0
                    ? '${strip.total} kayıt · özet metrik yok'
                    : 'Özet metrik için kayıt bekleniyor',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: typography.labelSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminUyeliklerTokens.horizontal,
        AdminUyeliklerTokens.chromeGap / 2,
        AdminUyeliklerTokens.horizontal,
        AdminUyeliklerTokens.chromeGap,
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

class UyeliklerCompactSearch extends StatelessWidget {
  const UyeliklerCompactSearch({
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
        AdminUyeliklerTokens.horizontal,
        0,
        AdminUyeliklerTokens.horizontal,
        AdminUyeliklerTokens.moduleGap,
      ),
      child: SizedBox(
        height: AdminUyeliklerTokens.searchHeight,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: AdminUyeliklerTokens.rowMetaSize,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminUyeliklerTokens.rowMetaSize,
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

class UyeliklerFilterChips extends StatelessWidget {
  const UyeliklerFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final UyeliklerFilter selected;
  final ValueChanged<UyeliklerFilter> onSelected;

  static const _filters = <(UyeliklerFilter, String)>[
    (UyeliklerFilter.all, 'Tümü'),
    (UyeliklerFilter.pending, 'Bekleyen'),
    (UyeliklerFilter.accepted, 'Kabul'),
    (UyeliklerFilter.expired, 'Süresi dolan'),
    (UyeliklerFilter.intervention, 'Müdahale'),
    (UyeliklerFilter.members, 'Üyeler'),
    (UyeliklerFilter.invite, 'Davet'),
    (UyeliklerFilter.last7d, 'Son 7g'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: AdminUyeliklerTokens.filterChipHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AdminUyeliklerTokens.horizontal,
          0,
          AdminUyeliklerTokens.horizontal,
          AdminUyeliklerTokens.moduleGap,
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
                fontSize: AdminUyeliklerTokens.rowChipSize,
                fontWeight: FontWeight.w700,
                color: active ? ext.accent : ext.textSecondary,
              ),
            ),
            selected: active,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            side: BorderSide(
              color: active
                  ? ext.accent.withValues(alpha: 0.55)
                  : ext.border.withValues(alpha: 0.4),
            ),
            backgroundColor: ext.surfaceElevated.withValues(alpha: 0.45),
            selectedColor: ext.accent.withValues(alpha: 0.12),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class UyeliklerQuickRouteRow extends StatelessWidget {
  const UyeliklerQuickRouteRow({
    super.key,
    required this.onCreateInvite,
    required this.onOfficeAdmin,
    required this.onKadro,
  });

  final VoidCallback onCreateInvite;
  final VoidCallback onOfficeAdmin;
  final VoidCallback onKadro;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminUyeliklerTokens.horizontal,
        0,
        AdminUyeliklerTokens.horizontal,
        AdminUyeliklerTokens.moduleGap,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _QuickChip(
            label: 'Yeni davet',
            icon: Icons.person_add_alt_1_rounded,
            onTap: onCreateInvite,
          ),
          _QuickChip(
            label: 'Ofis yönetimi',
            icon: Icons.apartment_rounded,
            onTap: onOfficeAdmin,
          ),
          _QuickChip(
            label: 'Kadro',
            icon: Icons.groups_rounded,
            onTap: onKadro,
          ),
          Text(
            'Hızlı geçiş',
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: AdminUyeliklerTokens.rowChipSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: ext.accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: AdminUyeliklerTokens.rowChipSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UyeliklerSectionHeader extends StatelessWidget {
  const UyeliklerSectionHeader({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminUyeliklerTokens.horizontal,
        AdminUyeliklerTokens.sectionGap,
        AdminUyeliklerTokens.horizontal,
        AdminUyeliklerTokens.moduleGap,
      ),
      child: Row(
        children: [
          Text(
            turkishUyelikSectionUpper(title),
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: AdminUyeliklerTokens.rowChipSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: AdminUyeliklerTokens.rowChipSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UyeliklerEmptyState extends StatelessWidget {
  const UyeliklerEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.group_add_rounded,
    this.actionLabel,
    this.onAction,
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: ext.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: AdminUyeliklerTokens.rowMetaSize + 1,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
