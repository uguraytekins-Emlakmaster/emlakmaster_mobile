import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';

/// Hata durumu — ham exception göstermez, yeniden dene sunar.
class AxionAgentErrorState extends StatelessWidget {
  const AxionAgentErrorState({
    super.key,
    this.message = 'Öneriler oluşturulurken bir sorun oluştu.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space6),
      decoration: t.surfaceCardDecoration(),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 32, color: t.warning),
          const SizedBox(height: DesignTokens.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSm,
              color: t.textSecondary,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: DesignTokens.space3),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Yeniden dene'),
            ),
          ],
        ],
      ),
    );
  }
}
