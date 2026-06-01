import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/widgets/admin_command_chrome.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
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
              _DailyHeaderEmblem(size: m.emblemSize, pad: m.emblemPad),
              SizedBox(width: m.titleGap),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: m.emblemPad * 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benim Günüm',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: ext.surfaceElevated.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ext.border.withValues(alpha: 0.38)),
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
                  : 'Liste yalnızca size atanmış görev ve müşterilerden türetilir.',
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

class _DailyHeaderEmblem extends StatelessWidget {
  const _DailyHeaderEmblem({required this.size, required this.pad});

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

class ConsultantDailySummaryStripView extends StatelessWidget {
  const ConsultantDailySummaryStripView({super.key, required this.summary});

  final ConsultantDailySummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final typography = AdminCommandTokens.stripTypography(context);
    final candidates = <(String, String, Color)>[
      if (summary.activeTasks > 0)
        (summary.activeTasks.toString(), 'Görev', ext.accent),
      if (summary.overdue > 0)
        (summary.overdue.toString(), 'Geciken', ext.danger),
      if (summary.hotCustomers > 0)
        (summary.hotCustomers.toString(), 'Sıcak', ext.warning),
      if (summary.todayContacts > 0)
        (summary.todayContacts.toString(), 'Bugün temas', ext.success),
      if (summary.customers > 0)
        (summary.customers.toString(), 'Müşteri', ext.info),
    ];
    final cells = candidates.take(5).toList(growable: false);

    final body = cells.isEmpty
        ? SizedBox(
            height: AdminCommandTokens.summaryStripHeight,
            child: Center(
              child: Text(
                'Özet metrik için canlı veri bekleniyor',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: typography.labelSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        : SizedBox(
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
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.chromeGap / 2,
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.chromeGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.68,
        child: body,
      ),
    );
  }
}

class ConsultantDailyCompactSearch extends StatelessWidget {
  const ConsultantDailyCompactSearch({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

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
      child: SizedBox(
        height: ConsultantDailyTokens.searchHeight,
        child: TextField(
          controller: controller,
          style: TextStyle(
            color: ext.textPrimary,
            fontSize: ConsultantDailyTokens.rowMetaSize,
            height: 1.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: ext.textTertiary,
              fontSize: ConsultantDailyTokens.rowMetaSize,
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

class ConsultantDailyFilterStrip extends StatelessWidget {
  const ConsultantDailyFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ConsultantDailyFilter selected;
  final ValueChanged<ConsultantDailyFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, ConsultantDailyTokens.moduleGap),
      child: SizedBox(
        height: ConsultantDailyTokens.filterChipHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: ConsultantDailyTokens.horizontal,
          ),
          itemCount: ConsultantDailyFilter.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final filter = ConsultantDailyFilter.values[index];
            return _FilterChipItem(
              label: filter.label,
              active: filter == selected,
              accent: ext.accent,
              onTap: () => onSelected(filter),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: active
          ? accent.withValues(alpha: 0.18)
          : ext.surfaceElevated.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.6)
                  : ext.border.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? accent : ext.textSecondary,
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
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
              Text(
                turkishDailySectionUpper(title),
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: ConsultantDailyTokens.rowChipSize,
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
                    fontSize: ConsultantDailyTokens.rowChipSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              note!,
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: ConsultantDailyTokens.rowChipSize,
                fontWeight: FontWeight.w600,
                height: 1.25,
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: ext.surfaceElevated.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: ext.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: ConsultantDailyTokens.rowMetaSize,
                  height: 1.3,
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
                fontSize: ConsultantDailyTokens.rowMetaSize + 1,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
            ],
          ],
        ),
      ),
    );
  }
}
