import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

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

/// Üst KPI bar — ölçek **S**; [AppThemeExtension] ile light/dark uyumlu.
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
        vertical: DesignTokens.space3,
      ),
      child: Row(
        children: [
          _KpiChip(
              label: 'Çağrı', value: '$totalCalls', icon: Icons.call_rounded),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(label: 'Cevaplanan', value: '$answeredCalls'),
          const SizedBox(width: DesignTokens.space2),
          _KpiChip(
              label: 'Lead',
              value: '$leadsCreated',
              icon: Icons.leaderboard_rounded),
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
    final ext = AppThemeExtension.of(context);
    final active = _hover;
    final emphasized = active || widget.highlight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: _aiRecommendationFor(widget.label, widget.value),
        preferBelow: false,
        child: Container(
          constraints: const BoxConstraints(
              minHeight: DashboardLayoutTokens.minHeightKpi),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius:
                BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
            border: Border.all(
              color: emphasized
                  ? ext.accent.withValues(alpha: 0.35)
                  : ext.borderSubtle,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: ext.shadowColor.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: emphasized ? ext.accent : ext.textSecondary,
                ),
                const SizedBox(width: DesignTokens.space1),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: AppTypography.metricValue(context).copyWith(
                      fontSize: DesignTokens.fontSizeLg,
                      color: emphasized ? ext.accent : ext.textPrimary,
                      shadows: emphasized
                          ? [
                              Shadow(
                                color: ext.accent.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.metricLabelGap),
                  Text(
                    widget.label,
                    style: AppTypography.metricLabel(context).copyWith(
                      color: emphasized
                          ? ext.accent.withValues(alpha: 0.9)
                          : ext.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.space1),
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: ext.accent.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
