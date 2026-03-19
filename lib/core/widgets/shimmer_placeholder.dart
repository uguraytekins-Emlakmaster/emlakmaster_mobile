import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme_extension.dart';
import '../theme/design_tokens.dart';

/// Görsel yüklenirken shimmer efekti. Tema ile uyumlu (light/dark).
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
    final ext = AppThemeExtension.of(context);
    return Shimmer.fromColors(
      baseColor: ext.shimmerBase,
      highlightColor: ext.shimmerHighlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ext.shimmerBase,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),
    );
  }
}
