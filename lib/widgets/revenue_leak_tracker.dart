import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Top bar altında: 24 saatten eski lead'lerden tahmini komisyon riski (kırmızı ton).
class RevenueLeakTracker extends StatelessWidget {
  const RevenueLeakTracker({
    super.key,
    this.estimatedRiskAmount = 1250000,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.danger.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: ext.danger.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: ext.danger.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Current Estimated Revenue at Risk: $formatted $currencySuffix',
                style: TextStyle(
                  color: ext.danger.withValues(alpha: 0.95),
                  fontSize: DesignTokens.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
