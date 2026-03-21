import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';

/// user null → login; user var ama role loading → loading; role var → child (app); role error → hata + çıkış.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const _AuthLoadingScreen(),
      error: (_, __) => const LoginPage(),
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        final roleAsync = ref.watch(currentRoleProvider);
        return roleAsync.when(
          loading: () => const _AuthLoadingScreen(),
          error: (e, _) => _AuthRoleErrorScreen(uid: user.uid, error: e),
          data: (_) => child,
        );
      },
    );
  }
}

/// Rol yüklenemedi (Firestore yetki/bağlantı vb.). Tekrar dene veya çıkış yap.
class _AuthRoleErrorScreen extends ConsumerWidget {
  const _AuthRoleErrorScreen({required this.uid, required this.error});

  final String uid;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = error.toString().toLowerCase();
    final isPermission = msg.contains('permission') || msg.contains('permission-denied');
    final isNetwork = msg.contains('network') || msg.contains('unavailable');
    String text = 'Hesap bilgileriniz yüklenemedi.';
    if (isPermission) text = 'Hesap bilgilerinize erişim yetkiniz yok. Yöneticinizle iletişime geçin.';
    if (isNetwork) text = 'Bağlantı kurulamadı. İnterneti kontrol edip tekrar deneyin.';

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: DesignTokens.primary),
              const SizedBox(height: 24),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.9), fontSize: 16),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(userDocStreamProvider(uid));
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tekrar dene'),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Çıkış yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface.withValues(alpha: 0.9),
                  side: BorderSide(color: onSurface.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoading(),
            const SizedBox(height: 24),
            Text(
              'Yükleniyor...',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.9), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
