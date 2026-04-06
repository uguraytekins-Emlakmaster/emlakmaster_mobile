import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/domain/revenue_models.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/revenue_ui_formatters.dart';
import 'package:flutter/material.dart';

/// Liste satırı: sıcaklık etiketi + skor (kompakt).
class RevenueBandScoreChip extends StatelessWidget {
  const RevenueBandScoreChip({super.key, required this.signal});

  final CustomerRevenueSignals signal;

  Color _bandColor(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    switch (signal.band) {
      case RevenueLeadBand.hot:
        return ext.success;
      case RevenueLeadBand.warm:
        return ext.warning;
      case RevenueLeadBand.cold:
        return ext.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final c = _bandColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            revenueBandLabelTr(signal.band),
            style: TextStyle(
              color: c,
              fontSize: DesignTokens.fontSizeXs,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '${signal.leadScore}',
              style: TextStyle(
                color: ext.textPrimary,
                fontSize: DesignTokens.fontSizeXs,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
