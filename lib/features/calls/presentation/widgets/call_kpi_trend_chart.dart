import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:flutter/material.dart';

/// KPI dağılımı — basit çubuk grafik (harici paket yok).
class CallKpiTrendChart extends StatelessWidget {
  const CallKpiTrendChart({
    super.key,
    required this.snapshot,
    this.height = 140,
  });

  final CallKpiPeriodSnapshot snapshot;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final c = snapshot.current;
    final bars = <_BarSpec>[
      _BarSpec('Gelen', c.incoming, ext.accent),
      _BarSpec('Giden', c.outgoing, ext.success),
      _BarSpec('Cevaplanan', c.answered, ext.accent),
      _BarSpec('Cevapsız', c.missed, ext.danger),
    ];
    final maxVal = bars.map((b) => b.value).fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxVal <= 0 ? 1.0 : maxVal.toDouble();

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in bars) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${b.value}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 72 * (b.value / scale).clamp(0.08, 1.0),
                    decoration: BoxDecoration(
                      color: b.color.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      border: Border.all(
                        color: b.color.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary,
                          fontSize: DesignTokens.fontSizeXs,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarSpec {
  const _BarSpec(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
