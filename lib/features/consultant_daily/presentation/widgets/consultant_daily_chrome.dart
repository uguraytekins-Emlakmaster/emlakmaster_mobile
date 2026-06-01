import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_components.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String turkishDailySectionUpper(String label) {
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

/// Smart cockpit command deck — hero identity + grounded intelligence bento.
class ConsultantDailyCommandDeck extends StatelessWidget {
  const ConsultantDailyCommandDeck({
    super.key,
    this.greetingName = '',
    required this.subtitle,
    required this.coverageNote,
    required this.summary,
    this.urgentSignals = 0,
  });

  final String greetingName;
  final String subtitle;
  final String coverageNote;
  final ConsultantDailySummary summary;
  final int urgentSignals;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final now = DateTime.now();
    final dateChip =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}';
    final m = AdminCommandTokens.headerMetrics(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final metrics = _cockpitMetrics(ext, summary);
    final pressure = _pressureRatio(summary);
    final urgent = summary.overdue + summary.hotCustomers;
    final statusChip = narrow
        ? (urgent > 0 ? '$urgent acil' : 'Sakin')
        : (urgent > 0
            ? '$urgent acil sinyal · $urgentSignals öncelikli'
            : 'Operasyon sakin · düşük baskı');

    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.horizontal,
        m.topInset,
        m.horizontal,
        ConsultantDailyTokens.moduleGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        goldRail: true,
        ambientStrength: 0.86,
        radius: ConsultantDailyTokens.surfaceRadius,
        padding: EdgeInsets.all(
          narrow ? 11 : ConsultantDailyTokens.commandPanelPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: premium.champagneGold.withValues(alpha: 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SessionAvatarButton(
                        size: narrow ? 40 : ConsultantDailyTokens.heroAvatarSize,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: urgent > 0
                              ? premium.champagneGold.withValues(alpha: 0.92)
                              : ext.success.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: premium.glassSurface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: m.titleGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingName.isNotEmpty
                            ? 'Merhaba, $greetingName'
                            : 'Executive cockpit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.pageEyebrow(context).copyWith(
                          fontSize: 11,
                          letterSpacing: 0.55,
                          color: premium.champagneGold.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Benim Günüm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.pageHeading(context).copyWith(
                          fontSize: m.titleSize + 1.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.45,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta(context).copyWith(
                          color: ext.textSecondary.withValues(alpha: 0.88),
                          fontSize: m.subtitleSize,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: _CockpitChip(
                    label: 'Bugün · $dateChip',
                    emphasized: true,
                    accent: premium.champagneGold,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: _CockpitChip(
                    label: statusChip,
                    icon: urgent > 0
                        ? Icons.bolt_rounded
                        : Icons.check_circle_outline_rounded,
                    accent: urgent > 0
                        ? premium.champagneGold
                        : ext.success.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              child: Stack(
                children: [
                  LinearProgressIndicator(
                    value: pressure,
                    minHeight: 4,
                    backgroundColor: ext.borderSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      premium.champagneGold.withValues(alpha: 0.28),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: pressure,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: PremiumGlassTokens.goldAccentGradient(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DailyHonestyNote(
              message: coverageNote.isNotEmpty
                  ? coverageNote
                  : 'Liste yalnızca size atanmış görev ve müşterilerden türetilir.',
              accent: premium.champagneGold,
            ),
            const SizedBox(height: ConsultantDailyTokens.commandDeckDividerGap),
            _DailyDeckDivider(accent: premium.champagneGold),
            const SizedBox(height: ConsultantDailyTokens.commandDeckDividerGap),
            if (metrics.isEmpty)
              SizedBox(
                height: ConsultantDailyTokens.bentoCellHeight,
                child: Center(
                  child: Text(
                    'Özet metrik için canlı veri bekleniyor',
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: ConsultantDailyTokens.summaryCellLabelSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (metrics.length >= 4)
              SizedBox(
                height: ConsultantDailyTokens.bentoCellHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: metrics.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => SizedBox(
                    width: narrow ? 76 : 88,
                    child: _SmartCockpitMetricCell(
                      spec: metrics[i],
                      compact: narrow,
                    ),
                  ),
                ),
              )
            else if (narrow && metrics.length > 3)
              SizedBox(
                height: ConsultantDailyTokens.bentoCellHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: metrics.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => SizedBox(
                    width: 76,
                    child: _SmartCockpitMetricCell(
                      spec: metrics[i],
                      compact: true,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: ConsultantDailyTokens.bentoCellHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0)
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: premium.champagneGold.withValues(alpha: 0.2),
                        ),
                      Expanded(
                        child: _SmartCockpitMetricCell(
                          spec: metrics[i],
                          compact: narrow,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _pressureRatio(ConsultantDailySummary s) {
    final urgent = s.overdue + s.hotCustomers;
    if (urgent <= 0) return 0.1;
    final denom = (s.activeTasks + s.hotCustomers).clamp(1, 24);
    return (urgent / denom).clamp(0.15, 1.0);
  }

  List<_CockpitMetricSpec> _cockpitMetrics(
    AppThemeExtension ext,
    ConsultantDailySummary s,
  ) {
    final specs = <_CockpitMetricSpec>[];
    if (s.activeTasks > 0) {
      specs.add(
        _CockpitMetricSpec(
          value: '${s.activeTasks}',
          label: 'Görev',
          story: s.overdue > 0 ? '${s.overdue} geciken görev' : 'Açık görevler',
          icon: Icons.checklist_rounded,
          accent: ext.accent,
        ),
      );
    }
    if (s.overdue > 0) {
      specs.add(
        _CockpitMetricSpec(
          value: '${s.overdue}',
          label: 'Geciken',
          story: 'Acil müdahale',
          icon: Icons.warning_amber_rounded,
          accent: Color.lerp(ext.warning, ext.danger, 0.48)!,
          emphasized: true,
        ),
      );
    }
    if (s.hotCustomers > 0) {
      specs.add(
        _CockpitMetricSpec(
          value: '${s.hotCustomers}',
          label: 'Sıcak',
          story: 'Kural tabanlı heat',
          icon: Icons.local_fire_department_rounded,
          accent: ext.warning,
        ),
      );
    }
    if (s.todayContacts > 0) {
      specs.add(
        _CockpitMetricSpec(
          value: '${s.todayContacts}',
          label: 'Bugün temas',
          story: 'Gerçek temas kaydı',
          icon: Icons.forum_rounded,
          accent: ext.success,
        ),
      );
    }
    if (s.customers > 0) {
      specs.add(
        _CockpitMetricSpec(
          value: '${s.customers}',
          label: 'Müşteri',
          story: 'Atanmış portföy',
          icon: Icons.groups_rounded,
          accent: ext.info,
        ),
      );
    }
    return specs.take(5).toList(growable: false);
  }
}

class _CockpitMetricSpec {
  const _CockpitMetricSpec({
    required this.value,
    required this.label,
    required this.story,
    required this.icon,
    required this.accent,
    this.emphasized = false,
  });

  final String value;
  final String label;
  final String story;
  final IconData icon;
  final Color accent;
  final bool emphasized;
}

class _SmartCockpitMetricCell extends StatelessWidget {
  const _SmartCockpitMetricCell({
    required this.spec,
    this.compact = false,
  });

  final _CockpitMetricSpec spec;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final valueSize = compact
        ? ConsultantDailyTokens.bentoValueSizeCompact
        : ConsultantDailyTokens.bentoValueSize;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 8,
        vertical: compact ? 4 : 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.icon, size: 13, color: spec.accent.withValues(alpha: 0.88)),
              const Spacer(),
              if (spec.emphasized)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: spec.accent.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            spec.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: spec.emphasized
                  ? premium.champagneGold
                  : spec.accent,
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ext.textSecondary.withValues(alpha: 0.82),
              fontSize: ConsultantDailyTokens.summaryCellLabelSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            spec.story,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 2,
            width: compact ? 28 : 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  spec.accent.withValues(alpha: spec.emphasized ? 0.85 : 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CockpitChip extends StatelessWidget {
  const _CockpitChip({
    required this.label,
    required this.accent,
    this.emphasized = false,
    this.icon,
  });

  final String label;
  final Color accent;
  final bool emphasized;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? accent.withValues(alpha: 0.16)
            : premium.glassSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(
          color: accent.withValues(alpha: emphasized ? 0.5 : 0.28),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyDeckDivider extends StatelessWidget {
  const _DailyDeckDivider({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accent.withValues(alpha: 0.28),
            ext.border.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          stops: const [0, 0.35, 0.65, 1],
        ),
      ),
    );
  }
}

class PremiumConsultantDailyHeader extends StatelessWidget {
  const PremiumConsultantDailyHeader({
    super.key,
    required this.subtitle,
    this.coverageNote = '',
  });

  final String subtitle;
  final String coverageNote;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final today = DateFormat('d MMM').format(DateTime.now());
    final m = AdminCommandTokens.headerMetrics(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.horizontal,
        m.topInset,
        m.horizontal,
        ConsultantDailyTokens.chromeGap / 2,
      ),
      child: ConsultantDashboardExecutiveSurface(
        goldRail: true,
        ambientStrength: 0.94,
        padding: EdgeInsets.all(
          narrow ? 11 : ConsultantDailyTokens.commandPanelPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DailyHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
                SizedBox(width: m.titleGap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: m.emblemPad * 0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Benim Günüm',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.pageHeading(context).copyWith(
                            fontSize: m.titleSize + 0.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.02,
                          ),
                        ),
                        SizedBox(height: m.titleToSubtitleGap + 1),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.meta(context).copyWith(
                            color: ext.textSecondary.withValues(alpha: 0.9),
                            fontSize: m.subtitleSize,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _DailyDateChip(
                  label: today,
                  metrics: m,
                  compact: narrow,
                ),
              ],
            ),
            SizedBox(height: m.honestyTopGap + 2),
            _DailyHonestyNote(
              message: coverageNote.isNotEmpty
                  ? coverageNote
                  : 'Liste yalnızca size atanmış görev ve müşterilerden türetilir.',
              accent: premium.champagneGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyHeaderEmblem extends StatelessWidget {
  const _DailyHeaderEmblem({required this.size, required this.pad});

  final double size;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: ext.surfaceElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: premium.champagneGold.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BrandEmblem(variant: BrandEmblemVariant.mini, size: size),
    );
  }
}

class _DailyDateChip extends StatelessWidget {
  const _DailyDateChip({
    required this.label,
    required this.metrics,
    this.compact = false,
  });

  final String label;
  final AdminCommandHeaderMetrics metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: ext.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: premium.champagneGold.withValues(alpha: 0.38),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ext.accent,
          fontSize: metrics.dateFontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.15,
          height: 1,
        ),
      ),
    );
  }
}

class _DailyHonestyNote extends StatelessWidget {
  const _DailyHonestyNote({required this.message, required this.accent});

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ext.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: accent.withValues(alpha: 0.85)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: ext.textSecondary.withValues(alpha: 0.92),
                fontSize: AdminCommandTokens.honestyNoteSize,
                fontWeight: FontWeight.w600,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Arama + filtre — tek premium kontrol paneli.
class ConsultantDailyControlsPanel extends StatelessWidget {
  const ConsultantDailyControlsPanel({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ConsultantDailyFilter selectedFilter;
  final ValueChanged<ConsultantDailyFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantDailyTokens.horizontal,
        0,
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.moduleGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.52,
        radius: ConsultantDailyTokens.surfaceRadius,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: AppThemeExtension.of(context).textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Akıllı filtre & arama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeExtension.of(context).textSecondary,
                      fontSize: ConsultantDailyTokens.commandEyebrowSize + 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PremiumSearchBar(
              controller: searchController,
              hintText: searchHint,
              compact: true,
            ),
            const SizedBox(height: 8),
            ConsultantDailyFilterStrip(
              selected: selectedFilter,
              onSelected: onFilterSelected,
              embedded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ConsultantDailyCompactSearch extends StatelessWidget {
  const ConsultantDailyCompactSearch({
    super.key,
    required this.controller,
    required this.hintText,
    this.embedded = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final field = SizedBox(
      height: ConsultantDailyTokens.searchHeight,
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: ext.textPrimary,
          fontSize: ConsultantDailyTokens.rowMetaSize + 0.5,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: ext.textTertiary,
            fontSize: ConsultantDailyTokens.rowMetaSize + 0.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: ext.accent.withValues(alpha: 0.75),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          filled: true,
          fillColor: ext.surfaceElevated.withValues(alpha: 0.62),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ext.border.withValues(alpha: 0.32)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ext.border.withValues(alpha: 0.32)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );

    if (embedded) return field;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantDailyTokens.horizontal,
        0,
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.moduleGap,
      ),
      child: field,
    );
  }
}

class ConsultantDailyFilterStrip extends StatelessWidget {
  const ConsultantDailyFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.embedded = false,
  });

  final ConsultantDailyFilter selected;
  final ValueChanged<ConsultantDailyFilter> onSelected;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final strip = SizedBox(
      height: ConsultantDailyTokens.filterChipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: embedded
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: ConsultantDailyTokens.horizontal,
              ),
        itemCount: ConsultantDailyFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = ConsultantDailyFilter.values[index];
          return _FilterChipItem(
            label: filter.label,
            icon: _filterIcon(filter),
            active: filter == selected,
            accent: ext.accent,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );

    if (embedded) return strip;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, ConsultantDailyTokens.moduleGap),
      child: strip,
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: active
          ? accent.withValues(alpha: 0.12)
          : ext.surfaceElevated.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.42)
                  : ext.border.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? accent : ext.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? accent : ext.textSecondary,
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _filterIcon(ConsultantDailyFilter filter) {
  return switch (filter) {
    ConsultantDailyFilter.all => Icons.grid_view_rounded,
    ConsultantDailyFilter.task => Icons.checklist_rounded,
    ConsultantDailyFilter.followUp => Icons.history_rounded,
    ConsultantDailyFilter.customer => Icons.person_rounded,
    ConsultantDailyFilter.today => Icons.today_rounded,
    ConsultantDailyFilter.overdue => Icons.warning_amber_rounded,
    ConsultantDailyFilter.priority => Icons.bolt_rounded,
    ConsultantDailyFilter.partial => Icons.info_outline_rounded,
  };
}

class ConsultantDailySectionHeader extends StatelessWidget {
  const ConsultantDailySectionHeader({
    super.key,
    required this.title,
    this.count,
    this.note,
  });

  final String title;
  final int? count;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.sectionGap,
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.moduleGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ConsultantDailyTokens.sectionAccentWidth,
                height: ConsultantDailyTokens.sectionAccentHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      premium.champagneGold.withValues(alpha: 0.9),
                      premium.champagneGold.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  turkishDailySectionUpper(title),
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: ConsultantDailyTokens.rowChipSize + 2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.85,
                  ),
                ),
              ),
              if (count != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: ext.surfaceElevated.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: ConsultantDailyTokens.rowChipSize + 0.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                note!,
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: ConsultantDailyTokens.rowChipSize + 0.5,
                  fontWeight: FontWeight.w600,
                  height: 1.28,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConsultantDailyInlineNote extends StatelessWidget {
  const ConsultantDailyInlineNote({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantDailyTokens.horizontal,
        0,
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.moduleGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.48,
        radius: ConsultantDailyTokens.surfaceRadius,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: ext.surfaceElevated.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(color: ext.border.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, size: 15, color: ext.textTertiary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: ConsultantDailyTokens.rowMetaSize + 0.5,
                  height: 1.34,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsultantDailyEmptyState extends StatelessWidget {
  const ConsultantDailyEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.event_available_rounded,
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConsultantDashboardExecutiveSurface(
          goldRail: true,
          ambientStrength: 0.72,
          radius: ConsultantDailyTokens.surfaceRadius,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: premium.champagneGold.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: ext.textTertiary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ext.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: ConsultantDailyTokens.rowMetaSize + 1,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
