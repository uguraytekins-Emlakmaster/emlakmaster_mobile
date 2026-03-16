import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/design_tokens.dart';

/// Hata durumu ekranı. Teknik mesaj göstermez; kullanıcı dostu mesaj + yeniden dene.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Bir hata oluştu. Lütfen tekrar deneyin.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: DesignTokens.danger,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DesignTokens.textSecondaryDark,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DesignTokens.space5),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tekrar Dene'),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: DesignTokens.brandWhite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
