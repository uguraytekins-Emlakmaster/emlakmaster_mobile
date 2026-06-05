import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:flutter/material.dart';

class EkipDetayLoadingSkeleton extends StatelessWidget {
  const EkipDetayLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumEkipDetayHeader(teamName: '…'),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminEkipDetayTokens.horizontal,
            AdminEkipDetayTokens.chromeGap,
            AdminEkipDetayTokens.horizontal,
            AdminEkipDetayTokens.moduleGap,
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
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AdminEkipDetayTokens.horizontal,
              0,
              AdminEkipDetayTokens.horizontal,
              AdminEkipDetayTokens.moduleGap,
            ),
            height: AdminEkipDetayTokens.rowMinHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      ],
    );
  }
}

class EkipDetayEmptyState extends StatelessWidget {
  const EkipDetayEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
