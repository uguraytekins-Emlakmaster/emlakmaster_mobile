import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../pages/login_page.dart';

/// user null → login; user var ama role loading → loading; role var → child (app).
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
      error: (e, _) => const _AuthLoadingScreen(),
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        final roleAsync = ref.watch(currentRoleProvider);
        return roleAsync.when(
          loading: () => const _AuthLoadingScreen(),
          error: (e, _) => const _AuthLoadingScreen(),
          data: (_) => child,
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00FF41)),
            SizedBox(height: 24),
            Text(
              'Yükleniyor...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
