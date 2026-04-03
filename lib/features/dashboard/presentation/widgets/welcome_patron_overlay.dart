import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/domain/entities/app_role.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
/// İlk kez superAdmin girişinde tek seferlik "Sistemin Temelleri Atıldı" karşılama.
class WelcomePatronOverlay extends ConsumerStatefulWidget {
  const WelcomePatronOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<WelcomePatronOverlay> createState() => _WelcomePatronOverlayState();
}

class _WelcomePatronOverlayState extends ConsumerState<WelcomePatronOverlay> {
  bool _alreadyShown = false;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(
      displayRoleOrNullProvider.select((r) => r == AppRole.superAdmin),
    );
    if (isSuperAdmin && !_alreadyShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _alreadyShown) return;
        _alreadyShown = true;
        _showWelcome(context);
      });
    }
    return widget.child;
  }

  void _showWelcome(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeExtension.of(context).card,
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hoş geldin Patron',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sistemin temelleri atıldı.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'Dashboard üzerinden ofis metriklerini, çağrı merkezini ve müşteri verilerini yönetebilirsin. Ayarlar\'dan rol değiştirerek farklı kullanıcı deneyimlerini test edebilirsin.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tamam', style: TextStyle(color: AppThemeExtension.of(context).accent)),
          ),
        ],
      ),
    );
  }
}
