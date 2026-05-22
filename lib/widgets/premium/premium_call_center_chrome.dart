import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_source.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

class PremiumCallCenterPageHeader extends StatelessWidget {
  const PremiumCallCenterPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        compact ? DesignTokens.space2 : DesignTokens.space3,
        DesignTokens.screenEdgePadding,
        compact ? DesignTokens.space2 : DesignTokens.space3,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: DesignTokens.space2),
            child: PremiumNavLeading(),
          ),
          BrandEmblem(
            variant: BrandEmblemVariant.mini,
            size: compact ? 34 : 40,
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.pageHeading(context).copyWith(
                    fontSize: compact
                        ? DesignTokens.fontSizeXl
                        : DesignTokens.fontSize2xl,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary,
                    fontSize: compact
                        ? DesignTokens.fontSizeSm
                        : DesignTokens.fontSizeMd,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class PremiumCallRecordsKpiCard extends StatelessWidget {
  const PremiumCallRecordsKpiCard({
    super.key,
    required this.snapshot,
    this.expanded = true,
    this.onToggleExpanded,
    this.onPeriodTap,
    this.onDetailTap,
    this.showHeroTotal = true,
  });

  final CallKpiPeriodSnapshot snapshot;
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onPeriodTap;
  final VoidCallback? onDetailTap;
  final bool showHeroTotal;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final stats = snapshot.current;
    final prev = snapshot.previous;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
      ),
      child: PremiumSurfaceCard(
        goldBorder: true,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3 + 2,
          vertical: DesignTokens.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: onPeriodTap,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ext.surface,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                      border:
                          Border.all(color: ext.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: ext.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          snapshot.period.labelTr,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: DesignTokens.fontSizeXs + 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (onPeriodTap != null) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded,
                              size: 16, color: ext.textSecondary),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (onDetailTap != null)
                  TextButton(
                    onPressed: onDetailTap,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Detaylı özet >',
                      style: TextStyle(
                        color: ext.accent,
                        fontSize: DesignTokens.fontSizeSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (onToggleExpanded != null)
                  TextButton.icon(
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: ext.textSecondary,
                    ),
                    label: Text(
                      expanded
                          ? 'İstatistikleri gizle'
                          : 'İstatistikleri göster',
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            if (showHeroTotal) ...[
              const SizedBox(height: DesignTokens.space3),
              Text(
                '${stats.total}',
                style: TextStyle(
                  color: ext.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Toplam çağrı',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
            ],
            if (expanded) ...[
              SizedBox(height: showHeroTotal ? DesignTokens.space3 : DesignTokens.space2),
              Row(
                children: [
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.call_received_rounded,
                      label: 'Gelen',
                      value: '${stats.incoming}',
                      color: ext.accent,
                      delta: snapshot.percentDelta(
                        stats.incoming,
                        prev.incoming,
                      ),
                      showDelta: snapshot.period == CallKpiPeriod.thisMonth,
                    ),
                  ),
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.call_made_rounded,
                      label: 'Giden',
                      value: '${stats.outgoing}',
                      color: ext.success,
                      delta: snapshot.percentDelta(
                        stats.outgoing,
                        prev.outgoing,
                      ),
                      showDelta: snapshot.period == CallKpiPeriod.thisMonth,
                    ),
                  ),
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Cevaplanan',
                      value: '${stats.answered}',
                      color: ext.accent,
                      delta: snapshot.percentDelta(
                        stats.answered,
                        prev.answered,
                      ),
                      showDelta: snapshot.period == CallKpiPeriod.thisMonth,
                    ),
                  ),
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.phone_missed_rounded,
                      label: 'Cevapsız',
                      value: '${stats.missed}',
                      color: ext.danger,
                      delta: snapshot.percentDelta(
                        stats.missed,
                        prev.missed,
                      ),
                      showDelta: snapshot.period == CallKpiPeriod.thisMonth,
                      invertDeltaColors: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiMini extends StatelessWidget {
  const _KpiMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.delta,
    this.showDelta = false,
    this.invertDeltaColors = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int? delta;
  final bool showDelta;
  final bool invertDeltaColors;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final d = delta;
    Widget? deltaChip;
    if (showDelta && d != null) {
      final positive = d >= 0;
      final good = invertDeltaColors ? !positive : positive;
      final sign = positive ? '+' : '';
      deltaChip = Text(
        '$sign$d%',
        style: TextStyle(
          color: good ? ext.success : ext.danger,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: ext.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: DesignTokens.fontSizeMd,
          ),
        ),
        if (deltaChip != null) deltaChip,
        Text(
          label,
          style: TextStyle(
            color: ext.textTertiary,
            fontSize: DesignTokens.fontSizeXs,
          ),
        ),
      ],
    );
  }
}

/// Hızlı filtre şeridi — [CallSurfaceQuickFilter] benzeri string etiketler.
class PremiumCallQuickFilterStrip extends StatelessWidget {
  const PremiumCallQuickFilterStrip({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.screenEdgePadding,
        ),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return PremiumFilterChip(
            label: labels[i],
            selected: selectedIndex == i,
            onTap: () => onSelected(i),
          );
        },
      ),
    );
  }
}

class PremiumCallSearchRow extends StatelessWidget {
  const PremiumCallSearchRow({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText =
        'Telefon, sonuç, not, müşteri veya danışman ara...',
    this.onSearchTap,
    this.onClear,
    this.showMic = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final VoidCallback? onSearchTap;
  final VoidCallback? onClear;
  final bool showMic;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        DesignTokens.space2,
        DesignTokens.screenEdgePadding,
        DesignTokens.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: PremiumSearchBar(
              controller: controller,
              focusNode: focusNode,
              hintText: hintText,
              showMic: showMic,
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Material(
            color: ext.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: ext.accent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Ara',
                      style: TextStyle(
                        color: ext.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sıralama satırı — mockup: “Sırala: Son arama” + liste görünümü.
class PremiumCallListToolbar extends StatelessWidget {
  const PremiumCallListToolbar({
    super.key,
    required this.sortMode,
    required this.onSortChanged,
    this.viewMode = CallListViewMode.list,
    this.onViewModeChanged,
    this.trailing,
  });

  final CallListSortMode sortMode;
  final ValueChanged<CallListSortMode> onSortChanged;
  final CallListViewMode viewMode;
  final ValueChanged<CallListViewMode>? onViewModeChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
      ),
      child: Row(
        children: [
          PopupMenuButton<CallListSortMode>(
            initialValue: sortMode,
            onSelected: onSortChanged,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 18, color: ext.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Sırala: ${sortMode.labelTr}',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
                Icon(Icons.expand_more_rounded,
                    size: 18, color: ext.textSecondary),
              ],
            ),
            itemBuilder: (context) => CallListSortMode.values
                .map(
                  (m) => PopupMenuItem(
                    value: m,
                    child: Text(m.labelTr),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          _ViewModeIcon(
            mode: CallListViewMode.list,
            selected: viewMode,
            icon: Icons.view_list_rounded,
            onTap: onViewModeChanged,
          ),
          const SizedBox(width: DesignTokens.space2),
          _ViewModeIcon(
            mode: CallListViewMode.grid,
            selected: viewMode,
            icon: Icons.grid_view_rounded,
            onTap: onViewModeChanged,
          ),
          const SizedBox(width: DesignTokens.space2),
          _ViewModeIcon(
            mode: CallListViewMode.chart,
            selected: viewMode,
            icon: Icons.bar_chart_rounded,
            onTap: onViewModeChanged,
          ),
          if (trailing != null) ...[
            const SizedBox(width: DesignTokens.space2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ViewModeIcon extends StatelessWidget {
  const _ViewModeIcon({
    required this.mode,
    required this.selected,
    required this.icon,
    this.onTap,
  });

  final CallListViewMode mode;
  final CallListViewMode selected;
  final IconData icon;
  final ValueChanged<CallListViewMode>? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final active = mode == selected;
    final color = active
        ? ext.accent
        : ext.textTertiary.withValues(alpha: onTap == null ? 0.35 : 0.55);
    return Tooltip(
      message: mode.labelTr,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                if (!active) onTap!(mode);
              },
        borderRadius: BorderRadius.circular(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

/// CRM / bu cihaz kaynak filtresi.
class PremiumCallSourceFilterStrip extends StatelessWidget {
  const PremiumCallSourceFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CallListSource selected;
  final ValueChanged<CallListSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.screenEdgePadding,
        ),
        itemCount: CallListSource.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final src = CallListSource.values[i];
          return PremiumFilterChip(
            label: src.labelTr,
            selected: selected == src,
            onTap: () => onSelected(src),
          );
        },
      ),
    );
  }
}

/// iOS / platform kısıt bilgisi — danışman listesi üstü.
class PremiumCallsPlatformHint extends StatelessWidget {
  const PremiumCallsPlatformHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        0,
        DesignTokens.screenEdgePadding,
        DesignTokens.space1,
      ),
      child: Text(
        message,
        style: TextStyle(
          color: ext.textTertiary,
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}
