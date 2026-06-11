import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';

/// Statik yükleme iskeleti — animasyonsuz (pil dostu), anlık üretim
/// beklendiği için yalnızca çok kısa süre görünür.
class AxionAgentLoadingSkeleton extends StatelessWidget {
  const AxionAgentLoadingSkeleton({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: t.surfaceCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines; i++) ...[
            if (i > 0) const SizedBox(height: DesignTokens.space2),
            Container(
              height: 12,
              width: i == 0 ? 160 : double.infinity,
              decoration: BoxDecoration(
                color: t.shimmerBase,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
