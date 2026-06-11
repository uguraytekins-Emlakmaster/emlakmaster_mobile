import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';

/// Dürüst boş durum — sahte içerik yerine net mesaj.
class AxionAgentEmptyState extends StatelessWidget {
  const AxionAgentEmptyState({
    super.key,
    this.title = 'Şu an öneri yok',
    this.message =
        'Mevcut kayıtlara göre bekleyen bir öneri bulunmuyor. '
        'Veri değiştikçe yeni öneriler oluşur.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space6),
      decoration: t.surfaceCardDecoration(),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 32, color: t.success),
          const SizedBox(height: DesignTokens.space3),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBase,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSm,
              color: t.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
