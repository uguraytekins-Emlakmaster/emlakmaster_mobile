import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Uygulama genelinde tutarlı yükleme göstergesi. DesignTokens.primary rengi kullanır.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.size = 32,
    this.strokeWidth = 2,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: DesignTokens.primary,
      ),
    );
  }
}
