import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_color_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_kpi_trend_chart.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_source.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
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
    final tight = compact;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ConsultantCallsTokens.horizontal,
        tight ? ConsultantCallsTokens.topInset + 4 : DesignTokens.space3,
        ConsultantCallsTokens.horizontal,
        tight ? ConsultantCallsTokens.headerBottomGap : ConsultantCallsTokens.chromeGap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!tight)
            const Padding(
              padding: EdgeInsets.only(right: DesignTokens.space2),
              child: PremiumNavLeading(),
            ),
          BrandEmblem(
            variant: BrandEmblemVariant.mini,
            size: tight ? ConsultantCallsTokens.headerEmblemSize : 40,
          ),
          SizedBox(width: tight ? 8 : DesignTokens.space2 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.pageHeading(context).copyWith(
                    fontSize: tight
                        ? ConsultantCallsTokens.headerTitleSize
                        : DesignTokens.fontSize2xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tight ? 2 : 4),
                Text(
                  subtitle,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary.withValues(alpha: 0.88),
                    fontSize: tight
                        ? ConsultantCallsTokens.headerSubtitleSize
                        : DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
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
    this.listViewMode = CallListViewMode.list,
  });

  final CallKpiPeriodSnapshot snapshot;
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onPeriodTap;
  final VoidCallback? onDetailTap;
  final bool showHeroTotal;
  final CallListViewMode listViewMode;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final stats = snapshot.current;
    final prev = snapshot.previous;
    final chartPrimary = listViewMode == CallListViewMode.chart;
    final compactWidth = MediaQuery.sizeOf(context).width < 340;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap,
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        goldBorder: true,
        goldRail: true,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                      color: premium.champagneGold.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                      border: Border.all(
                        color: premium.champagneGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: premium.champagneGold),
                        const SizedBox(width: 5),
                        Text(
                          snapshot.period.labelTr,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (onPeriodTap != null) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded,
                              size: 15, color: premium.champagneGold),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (onDetailTap != null)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onDetailTap,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Detay >',
                            style: TextStyle(
                              color: premium.champagneGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onToggleExpanded != null)
                  IconButton(
                    onPressed: onToggleExpanded,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: premium.champagneGold,
                    ),
                    tooltip: expanded
                        ? 'İstatistikleri gizle'
                        : 'İstatistikleri göster',
                  ),
              ],
            ),
            if (showHeroTotal) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        PremiumColorTokens.champagneGoldLight,
                        premium.champagneGold,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      '${stats.total}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: compactWidth ? 32 : 36,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Toplam çağrı · ${stats.answered} cevap · ${stats.missed} cevapsız',
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (expanded) ...[
              SizedBox(
                  height: showHeroTotal
                      ? ConsultantCallsTokens.sectionGap
                      : ConsultantCallsTokens.chromeGap),
              if (chartPrimary)
                CallKpiTrendChart(snapshot: snapshot)
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          showDelta:
                              snapshot.period == CallKpiPeriod.thisMonth,
                        ),
                      ),
                      _KpiStripDivider(premium: premium),
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
                          showDelta:
                              snapshot.period == CallKpiPeriod.thisMonth,
                        ),
                      ),
                      _KpiStripDivider(premium: premium),
                      Expanded(
                        child: _KpiMini(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Cevap',
                          value: '${stats.answered}',
                          color: ext.accent,
                          delta: snapshot.percentDelta(
                            stats.answered,
                            prev.answered,
                          ),
                          showDelta:
                              snapshot.period == CallKpiPeriod.thisMonth,
                        ),
                      ),
                      _KpiStripDivider(premium: premium),
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
                          showDelta:
                              snapshot.period == CallKpiPeriod.thisMonth,
                          invertDeltaColors: true,
                        ),
                      ),
                    ],
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: ext.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1,
              ),
            ),
          ),
          if (deltaChip != null) deltaChip,
          Text(
            label,
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KpiStripDivider extends StatelessWidget {
  const _KpiStripDivider({required this.premium});

  final PremiumThemeExtension premium;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: premium.champagneGold.withValues(alpha: 0.2),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ConsultantCallsTokens.horizontal,
        vertical: ConsultantCallsTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SizedBox(
      height: ConsultantCallsTokens.quickFilterHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          return PremiumFilterChip(
            label: labels[i],
            selected: selectedIndex == i,
            onTap: () => onSelected(i),
            dense: true,
          );
        },
      ),
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap,
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.75,
        padding: EdgeInsets.fromLTRB(
          ConsultantCallsTokens.searchSurfacePaddingH,
          ConsultantCallsTokens.searchSurfacePaddingV,
          ConsultantCallsTokens.searchSurfacePaddingH,
          ConsultantCallsTokens.searchSurfacePaddingV,
        ),
        child: SizedBox(
          height: ConsultantCallsTokens.searchBarHeight,
          child: PremiumSearchBar(
            controller: controller,
            focusNode: focusNode,
            hintText: hintText,
            showMic: showMic,
            compact: true,
          ),
        ),
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
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap / 2,
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<CallListSortMode>(
                initialValue: sortMode,
                onSelected: onSortChanged,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: ext.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Sırala: ${sortMode.labelTr}',
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Icon(Icons.expand_more_rounded,
                        size: 16, color: ext.textSecondary),
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
            ),
          ),
          const SizedBox(width: 2),
          _ViewModeIcon(
            mode: CallListViewMode.list,
            selected: viewMode,
            icon: Icons.view_list_rounded,
            onTap: onViewModeChanged,
          ),
          _ViewModeIcon(
            mode: CallListViewMode.grid,
            selected: viewMode,
            icon: Icons.grid_view_rounded,
            onTap: onViewModeChanged,
          ),
          _ViewModeIcon(
            mode: CallListViewMode.chart,
            selected: viewMode,
            icon: Icons.bar_chart_rounded,
            onTap: onViewModeChanged,
          ),
          if (trailing != null) trailing!,
        ],
        ),
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
    final premium = PremiumThemeExtension.of(context);
    final active = mode == selected;
    final color = active
        ? premium.champagneGold
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
        child: Icon(icon, color: color, size: 20),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ConsultantCallsTokens.horizontal,
        vertical: ConsultantCallsTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: SizedBox(
      height: ConsultantCallsTokens.filterStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: CallListSource.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final src = CallListSource.values[i];
          return PremiumFilterChip(
            label: src.labelTr,
            selected: selected == src,
            onTap: () => onSelected(src),
            dense: true,
          );
        },
      ),
        ),
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
        ConsultantCallsTokens.horizontal,
        0,
        ConsultantCallsTokens.horizontal,
        ConsultantCallsTokens.chromeGap,
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
