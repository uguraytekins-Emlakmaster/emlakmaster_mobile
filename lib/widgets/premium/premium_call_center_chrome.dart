import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/branding/brand_emblem.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
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
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenEdgePadding,
        DesignTokens.space3,
        DesignTokens.screenEdgePadding,
        DesignTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.space2),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: ext.textSecondary, size: 20),
              ),
            ),
          const BrandEmblem(variant: BrandEmblemVariant.mini, size: 40),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.pageHeading(context).copyWith(
                    fontSize: DesignTokens.fontSize2xl,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary,
                  ),
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
    this.onDetailTap,
  });

  final CallRecordKpiStats stats;
  final String periodLabel;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.screenEdgePadding,
        vertical: DesignTokens.space2,
      ),
      child: PremiumSurfaceCard(
        goldBorder: true,
        padding: const EdgeInsets.all(DesignTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
                          size: 14, color: ext.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: DesignTokens.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (onDetailTap != null)
                  TextButton(
                    onPressed: onDetailTap,
                    child: Text(
                      'Detaylı özet >',
                      style: TextStyle(
                        color: ext.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              '${stats.total}',
              style: AppTypography.metricValue(context).copyWith(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: ext.accent,
              ),
            ),
            Text(
              'Toplam çağrı',
              style: TextStyle(
                color: ext.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
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
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: ext.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: DesignTokens.fontSizeLg,
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
      height: 44,
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
