import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_chrome.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:flutter/material.dart';

class KadroLoadingSkeleton extends StatelessWidget {
  const KadroLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumKadroHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminKadroTokens.horizontal,
            AdminKadroTokens.chromeGap,
            AdminKadroTokens.horizontal,
            AdminKadroTokens.moduleGap,
          ),
          child: Container(
            height: AdminCommandTokens.summaryStripHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        const SizedBox(height: AdminKadroTokens.searchHeight + 12),
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AdminKadroTokens.horizontal,
              0,
              AdminKadroTokens.horizontal,
              AdminKadroTokens.moduleGap,
            ),
            height: AdminKadroTokens.rowMinHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      ],
    );
  }
}

class KadroEmptyState extends StatelessWidget {
  const KadroEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ext.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: ext.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
          ],
        ],
      ),
    );
  }
}
