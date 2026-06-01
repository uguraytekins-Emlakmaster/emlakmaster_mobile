import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:flutter/material.dart';

/// Hafif yükleme iskeleti — shimmer/sonsuz animasyon yok (perf güvenli).
class ConsultantDailySkeleton extends StatelessWidget {
  const ConsultantDailySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    Widget block(double h, {double? w, double r = 12}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: ext.surfaceElevated.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.horizontal,
        ConsultantDailyTokens.horizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(56, r: 16),
          const SizedBox(height: 14),
          block(AdminStripHeight.value, r: 18),
          const SizedBox(height: 14),
          block(ConsultantDailyTokens.searchHeight),
          const SizedBox(height: 12),
          Row(
            children: [
              block(ConsultantDailyTokens.filterChipHeight, w: 64),
              const SizedBox(width: 6),
              block(ConsultantDailyTokens.filterChipHeight, w: 64),
              const SizedBox(width: 6),
              block(ConsultantDailyTokens.filterChipHeight, w: 64),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            block(ConsultantDailyTokens.rowMinHeight, r: 16),
            const SizedBox(height: ConsultantDailyTokens.moduleGap),
          ],
        ],
      ),
    );
  }
}

/// Strip yüksekliği için sabit (skeleton'da context'siz kullanım).
abstract final class AdminStripHeight {
  static const double value = 64;
}
