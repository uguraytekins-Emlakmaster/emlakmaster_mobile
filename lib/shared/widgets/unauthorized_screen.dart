import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme_extension.dart';

/// Yetkisiz erişim: rol bu sayfayı görmeye yetkili değil.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({
    super.key,
    this.message,
    this.showBackButton = true,
  });

  final String? message;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: ext.textPrimary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Yetkisiz Erişim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'Bu sayfayı görüntüleme yetkiniz yok. Yetki için yöneticinize başvurun.',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (showBackButton) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go(AppRouter.routeHome),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: const Text('Ana Sayfaya Dön'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
