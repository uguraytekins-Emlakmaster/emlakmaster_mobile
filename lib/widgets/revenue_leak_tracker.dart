import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Üst kimlik altı: gelir riski sinyali — kontrollü, yönetici tonunda şerit.
/// [estimatedRiskAmount] gerçek veri bağlanana kadar 0 bırakılabilir; >0 iken öncelik şeridi gösterilir.
class RevenueLeakTracker extends StatelessWidget {
  const RevenueLeakTracker({
    super.key,
    this.estimatedRiskAmount = 0,
    this.currencySuffix = 'TL',
  });

  final int estimatedRiskAmount;
  final String currencySuffix;

  static String _formatAmount(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final formatted = _formatAmount(estimatedRiskAmount);
    final calm = estimatedRiskAmount <= 0;

    if (calm) {
      return Semantics(
        label:
            'Gelir riski sinyali: kontrol altında. Kritik temasız lead bildirimi yok.',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            border: Border(
              bottom: BorderSide(color: ext.border.withValues(alpha: 0.45)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 20,
                  color: ext.accent.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gelir riski sinyali sakin — 24 saat üstü kritik lead bildirimi görünmüyor.',
                    style: AppTypography.body(context).copyWith(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label:
          'Dikkat: tahmini gelir riski $formatted $currencySuffix. Temasız leadlerden model tahmini.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.danger.withValues(alpha: 0.08),
          border: Border(
            bottom: BorderSide(color: ext.danger.withValues(alpha: 0.28)),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: ext.danger.withValues(alpha: 0.85),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 22,
                        color: ext.danger.withValues(alpha: 0.92),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gelir riski — öncelikli inceleme',
                              style: AppTypography.metricLabel(context).copyWith(
                                color: ext.danger.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '24 saati aşan temasız leadler için tahmini etki: '
                              '$formatted $currencySuffix. Aksiyonu müşteri ve takım kartlarından yürütün.',
                              style: TextStyle(
                                color: ext.textPrimary.withValues(alpha: 0.88),
                                fontSize: DesignTokens.fontSizeSm,
                                fontWeight: FontWeight.w500,
                                height: 1.38,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
