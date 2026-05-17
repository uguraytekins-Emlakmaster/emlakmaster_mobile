import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';

/// Çağrı merkezi / kayıtlar ekranları için ortak KPI özeti.
class CallRecordKpiStats {
  const CallRecordKpiStats({
    required this.total,
    required this.incoming,
    required this.outgoing,
    required this.answered,
    required this.missed,
  });

  final int total;
  final int incoming;
  final int outgoing;
  final int answered;
  final int missed;

  static CallRecordKpiStats fromFirestoreDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var incoming = 0;
    var outgoing = 0;
    var missed = 0;
    var answered = 0;
    for (final d in docs) {
      final data = d.data();
      final direction = (data['direction'] as String? ?? 'outgoing').toLowerCase();
      if (direction == 'incoming') {
        incoming++;
      } else {
        outgoing++;
      }
      final oc = (data['outcome'] as String? ?? '').toLowerCase();
      if (oc == 'missed' || oc == 'no_answer' || oc == 'cevapsiz') {
        missed++;
      } else if (oc.isNotEmpty) {
        answered++;
      }
    }
    final total = docs.length;
    return CallRecordKpiStats(
      total: total,
      incoming: incoming,
      outgoing: outgoing,
      answered: answered,
      missed: missed,
    );
  }
}

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
        crossAxisAlignment: CrossAxisAlignment.center,
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
    required this.stats,
    this.periodLabel = 'Bu ay',
    this.expanded = true,
    this.onToggleExpanded,
  });

  final CallRecordKpiStats stats;
  final String periodLabel;
  final bool expanded;
  final VoidCallback? onToggleExpanded;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ext.surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                    border: Border.all(color: ext.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: ext.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: DesignTokens.fontSizeXs + 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
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
                      expanded ? 'İstatistikleri gizle' : 'İstatistikleri göster',
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
            if (expanded) ...[
              const SizedBox(height: DesignTokens.space3),
              Row(
                children: [
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.call_received_rounded,
                      label: 'Gelen',
                      value: '${stats.incoming}',
                      color: ext.accent,
                    ),
                  ),
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.call_made_rounded,
                      label: 'Giden',
                      value: '${stats.outgoing}',
                      color: ext.success,
                    ),
                  ),
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Cevaplanan',
                      value: '${stats.answered}',
                      color: ext.accent,
                    ),
                  ),
                  Expanded(
                    child: _KpiMini(
                      icon: Icons.phone_missed_rounded,
                      label: 'Cevapsız',
                      value: '${stats.missed}',
                      color: ext.danger,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
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
