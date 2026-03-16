import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/design_tokens.dart';

/// Görsel yüklenirken shimmer efekti. CachedNetworkImage placeholder ile kullanılır.
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? DesignTokens.shimmerBase : DesignTokens.shimmerBaseLight;
    final highlightColor = isDark ? DesignTokens.shimmerHighlight : DesignTokens.shimmerHighlightLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),
    );
  }
}
