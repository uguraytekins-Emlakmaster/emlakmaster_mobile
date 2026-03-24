import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
/// Ofis yokken: oluştur veya katıl seçimi (merkezi yönlendirme).
class OfficeGatePage extends StatelessWidget {
  const OfficeGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Ofisinize bağlanın',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ext.foreground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rainbow CRM çok kiracılı çalışır. Her kullanıcı bir ofise aittir.\n'
                'Yeni ofis oluşturun veya davet koduyla ekibe katılın.',
                style: TextStyle(
                  color: ext.foregroundSecondary,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              _Tile(
                icon: Icons.add_business_rounded,
                title: 'Ofis oluştur',
                subtitle: 'Siz ofis sahibi (owner) olursunuz.',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(AppRouter.routeOfficeCreate);
                },
              ),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.vpn_key_rounded,
                title: 'Davet koduyla katıl',
                subtitle: 'Yöneticinizden aldığınız kodu girin.',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push(AppRouter.routeOfficeJoin);
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await AuthService.instance.signOut();
                  if (context.mounted) context.go(AppRouter.routeLogin);
                },
                child: Text(
                  'Çıkış yap',
                  style: TextStyle(color: ext.foregroundSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Icon(icon, color: ext.accent, size: 28),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ext.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ext.foregroundSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ext.foregroundSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
