import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

class StartupRecoveryScaffold extends StatelessWidget {
  const StartupRecoveryScaffold({
    super.key,
    required this.title,
    required this.message,
    this.detail,
    this.primaryLabel = 'Tekrar dene',
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon = Icons.sync_problem_rounded,
  });

  final String title;
  final String message;
  final String? detail;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 58, color: ext.accent),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ext.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (detail != null && detail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ext.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ext.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        detail!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ext.textTertiary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: onPrimary,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(primaryLabel),
                      ),
                      if (secondaryLabel != null && onSecondary != null)
                        OutlinedButton.icon(
                          onPressed: onSecondary,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(secondaryLabel!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
