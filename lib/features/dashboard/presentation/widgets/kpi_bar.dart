import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Üst KPI bar: bugün toplam çağrı, cevaplanan, lead, sıcak fırsat vb.
class KpiBar extends StatelessWidget {
  const KpiBar({
    super.key,
    this.totalCalls = 0,
    this.answeredCalls = 0,
    this.missedCalls = 0,
    this.leadsCreated = 0,
    this.hotOpportunities = 0,
    this.followUpPending = 0,
    this.activeAdvisors = 0,
    this.activeCalls = 0,
  });

  final int totalCalls;
  final int answeredCalls;
  final int missedCalls;
  final int leadsCreated;
  final int hotOpportunities;
  final int followUpPending;
  final int activeAdvisors;
  final int activeCalls;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
      child: Row(
        children: [
          _KpiChip(label: 'Çağrı', value: '$totalCalls', icon: Icons.call_rounded),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Cevaplanan', value: '$answeredCalls'),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Lead', value: '$leadsCreated', icon: Icons.leaderboard_rounded),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Sıcak', value: '$hotOpportunities', highlight: true),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Follow-up', value: '$followUpPending'),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Aktif danışman', value: '$activeAdvisors'),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Görüşmede', value: '$activeCalls', highlight: true),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? DesignTokens.primary.withOpacity(0.15)
            : DesignTokens.surfaceDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: highlight
            ? Border.all(color: DesignTokens.primary.withOpacity(0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: highlight ? DesignTokens.primary : DesignTokens.textSecondaryDark,
            ),
            const SizedBox(width: DesignTokens.space1),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: DesignTokens.fontSizeMd,
                  color: highlight ? DesignTokens.primary : DesignTokens.textPrimaryDark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXs,
                  color: DesignTokens.textTertiaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
