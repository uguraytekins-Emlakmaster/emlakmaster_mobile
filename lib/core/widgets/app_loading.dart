import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

/// Uygulama genelinde tutarlı yükleme göstergesi. AppThemeExtension.of(context).accent rengi kullanır.
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
        color: AppThemeExtension.of(context).accent,
      ),
    );
  }
}
