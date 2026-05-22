import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_kpi_trend_chart.dart';
import 'package:flutter/material.dart';

/// KPI kartı “Detaylı özet” — dönem karşılaştırmalı özet.
Future<void> showCallKpiDetailSheet(
  BuildContext context, {
  required CallKpiPeriodSnapshot snapshot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CallKpiDetailSheetBody(snapshot: snapshot),
  );
}

class _CallKpiDetailSheetBody extends StatelessWidget {
  const _CallKpiDetailSheetBody({required this.snapshot});

  final CallKpiPeriodSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final c = snapshot.current;
    final p = snapshot.previous;
    final periodLabel = snapshot.period.labelTr;

    Widget row(String label, int current, int previous) {
      final delta = snapshot.percentDelta(current, previous);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              '$current',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ext.accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (snapshot.period == CallKpiPeriod.thisMonth &&
                delta != null) ...[
              const SizedBox(width: DesignTokens.space2),
              Text(
                '${delta >= 0 ? '+' : ''}$delta%',
                style: TextStyle(
                  color: delta >= 0 ? ext.success : ext.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        border: Border.all(color: ext.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Detaylı özet · $periodLabel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            '${c.total} toplam çağrı',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ext.textSecondary,
                ),
          ),
          const SizedBox(height: DesignTokens.space3),
          CallKpiTrendChart(snapshot: snapshot),
          const SizedBox(height: DesignTokens.space3),
          const Divider(height: 1),
          row('Gelen', c.incoming, p.incoming),
          row('Giden', c.outgoing, p.outgoing),
          row('Cevaplanan', c.answered, p.answered),
          row('Cevapsız', c.missed, p.missed),
          if (snapshot.period == CallKpiPeriod.thisMonth)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.space2),
              child: Text(
                'Yüzde değişim önceki aya göre hesaplanır.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ext.textTertiary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
