import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Kısa AI önerisi (danışman KPI’sına göre).
String _aiRecommendationFor(String label, String value) {
  switch (label) {
    case 'Çağrı':
      return 'Günlük hedefe yaklaşmak için sabah erken saatlerde arama yoğunluğunu artırın.';
    case 'Cevaplanan':
      return 'Cevaplanan oranı yüksek; kaçırılan çağrıları takip listesine ekleyin.';
    case 'Lead':
      return 'Yeni lead’leri 24 saat içinde ilk temasla sıcak tutun.';
    case 'Sıcak':
      return 'Sıcak fırsatları bugün kapatmaya öncelik verin.';
    case 'Follow-up':
      return 'Bekleyen follow-up’ları hafta sonuna bırakmayın.';
    case 'Aktif danışman':
      return 'Ekip dağılımını dengelemek için boş slotları değerlendirin.';
    case 'Görüşmede':
      return 'Aktif görüşmeler bitince hızlı not alıp sonraki adımı planlayın.';
    default:
      return 'Bu metrik için performansı günlük hedeflerle karşılaştırın.';
  }
}

/// Üst KPI bar: neomorphic chip’ler, Antique Gold hover glow, AI Coach ikonu.
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

class _KpiChip extends StatefulWidget {
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
  State<_KpiChip> createState() => _KpiChipState();
}

class _KpiChipState extends State<_KpiChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = _hover;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: _aiRecommendationFor(widget.label, widget.value),
        preferBelow: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space2,
          ),
          decoration: DesignTokens.cardNeomorphic(hoverOrActive: active || widget.highlight),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: (active || widget.highlight)
                      ? DesignTokens.antiqueGold
                      : DesignTokens.textSecondaryDark,
                ),
                const SizedBox(width: DesignTokens.space1),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: DesignTokens.fontSizeMd,
                      color: (active || widget.highlight)
                          ? DesignTokens.antiqueGold
                          : DesignTokens.textPrimaryDark,
                      shadows: (active || widget.highlight)
                          ? [
                              Shadow(
                                color: DesignTokens.antiqueGold.withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXs,
                      color: active ? DesignTokens.antiqueGold.withOpacity(0.9) : DesignTokens.textTertiaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.space1),
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: DesignTokens.antiqueGold.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
