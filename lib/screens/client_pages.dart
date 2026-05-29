import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_discovery_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_favorites_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Müşteri Keşfet — premium client portal discovery surface.
class ClientSearchPage extends StatelessWidget {
  const ClientSearchPage({super.key});

  @override
  Widget build(BuildContext context) => const ClientPortalDiscoveryPage();
}

/// Müşteri Favoriler — dürüst boş durum; sahte örnek ilan yok.
class ClientFavoritesPage extends StatelessWidget {
  const ClientFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) => const ClientPortalFavoritesPage();
}

/// Müşteri: Mesajlar — iletişim kanalları.
class ClientMessagesPage extends StatelessWidget {
  const ClientMessagesPage({super.key});

  Future<void> _open(Uri u) async {
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppThemeExtension.of(context).background
        : AppThemeExtension.of(context).background;
    final surface = isDark
        ? AppThemeExtension.of(context).surface
        : AppThemeExtension.of(context).surface;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark
        ? AppThemeExtension.of(context).border
        : AppThemeExtension.of(context).border;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'İletişim',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Danışmanınızla görüşmek için aşağıdaki seçeneklerden birini kullanın.',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space5),
            _msgTile(
              context,
              surface: surface,
              border: border,
              onSurface: onSurface,
              icon: Icons.chat_rounded,
              title: 'WhatsApp ile yazın',
              subtitle: 'Hızlı mesaj için WhatsApp açılır',
              onTap: () {
                AppFeedback.lightImpact();
                _open(Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent('Merhaba, EmlakMaster müşterisiyim. Görüşmek istiyorum.')}'));
              },
            ),
            const SizedBox(height: 12),
            _msgTile(
              context,
              surface: surface,
              border: border,
              onSurface: onSurface,
              icon: Icons.phone_rounded,
              title: 'Telefon',
              subtitle: 'Ofis hattını arayın',
              onTap: () {
                AppFeedback.lightImpact();
                _open(Uri(scheme: 'tel', path: '+908503021234'));
              },
            ),
            const SizedBox(height: 12),
            _msgTile(
              context,
              surface: surface,
              border: border,
              onSurface: onSurface,
              icon: Icons.email_rounded,
              title: 'E-posta',
              subtitle: 'info@rainbowgayrimenkul.com (örnek)',
              onTap: () {
                AppFeedback.lightImpact();
                _open(Uri(
                    scheme: 'mailto',
                    path: 'info@example.com',
                    queryParameters: {'subject': 'EmlakMaster müşteri'}));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _msgTile(
    BuildContext context, {
    required Color surface,
    required Color border,
    required Color onSurface,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    AppThemeExtension.of(context).accent.withValues(alpha: 0.2),
                child: Icon(icon, color: AppThemeExtension.of(context).accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: onSurface, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: TextStyle(
                            color: onSurface.withValues(alpha: 0.65),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  size: 20, color: onSurface.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Müşteri: Sanal tur — örnek 360 içerikler.
class ClientVirtualTourPage extends StatelessWidget {
  const ClientVirtualTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppThemeExtension.of(context).background
        : AppThemeExtension.of(context).background;
    final surface = isDark
        ? AppThemeExtension.of(context).surface
        : AppThemeExtension.of(context).surface;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark
        ? AppThemeExtension.of(context).border
        : AppThemeExtension.of(context).border;

    final tours = [
      (
        'Örnek daire turu',
        'YouTube üzerinde 360° örnek',
        'https://www.youtube.com/results?search_query=360+apartment+tour'
      ),
      (
        'Boş dağıtım',
        'Mimari gezinti örneği',
        'https://www.youtube.com/results?search_query=real+estate+virtual+tour'
      ),
    ];

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'Sanal tur',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Aşağıdaki bağlantılar harici sitede örnek sanal tur içerikleri açar.',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.75), fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space5),
            ...tours.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    child: InkWell(
                      onTap: () async {
                        AppFeedback.lightImpact();
                        final u = Uri.parse(t.$3);
                        if (await canLaunchUrl(u)) {
                          await launchUrl(u,
                              mode: LaunchMode.externalApplication);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Bağlantı açılamadı.')),
                          );
                        }
                      },
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusLg),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(DesignTokens.space5),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLg),
                          border:
                              Border.all(color: border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppThemeExtension.of(context)
                                    .accent
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.threesixty_rounded,
                                  color: AppThemeExtension.of(context).accent,
                                  size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.$1,
                                      style: TextStyle(
                                          color: onSurface,
                                          fontWeight: FontWeight.w700)),
                                  Text(t.$2,
                                      style: TextStyle(
                                          color:
                                              onSurface.withValues(alpha: 0.65),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            Icon(Icons.play_circle_fill_rounded,
                                color: AppThemeExtension.of(context).accent,
                                size: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Müşteri: Profil — hesap ve çıkış.
class ClientProfilePage extends ConsumerWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final avatarLetter = () {
      final label = user?.email ?? user?.displayName ?? 'M';
      return label.isNotEmpty ? label[0].toUpperCase() : '?';
    }();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppThemeExtension.of(context).background
        : AppThemeExtension.of(context).background;
    final surface = isDark
        ? AppThemeExtension.of(context).surface
        : AppThemeExtension.of(context).surface;
    final onSurface = theme.colorScheme.onSurface;
    final border = isDark
        ? AppThemeExtension.of(context).border
        : AppThemeExtension.of(context).border;

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space5),
          children: [
            Text(
              'Profil',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.space5),
            Container(
              padding: const EdgeInsets.all(DesignTokens.space5),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(color: border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppThemeExtension.of(context)
                        .accent
                        .withValues(alpha: 0.2),
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                          color: AppThemeExtension.of(context).accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Giriş yapılmamış',
                          style: TextStyle(
                              color: onSurface, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Müşteri hesabı',
                          style: TextStyle(
                              color: onSurface.withValues(alpha: 0.65),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(color: border.withValues(alpha: 0.5)),
              ),
              tileColor: surface,
              leading: Icon(Icons.privacy_tip_outlined,
                  color: AppThemeExtension.of(context).accent),
              title:
                  Text('KVKK & gizlilik', style: TextStyle(color: onSurface)),
              subtitle: Text('Verileriniz nasıl kullanılır?',
                  style: TextStyle(
                      color: onSurface.withValues(alpha: 0.65), fontSize: 12)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: onSurface.withValues(alpha: 0.4)),
              onTap: () {
                AppFeedback.lightImpact();
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Gizlilik'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Kişisel verileriniz yalnızca hizmet sunumu ve yasal yükümlülükler kapsamında işlenir. '
                        'Detaylı bilgi için ofisimizle iletişime geçebilirsiniz.',
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tamam')),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: DesignTokens.space6),
            if (user != null)
              OutlinedButton.icon(
                onPressed: () async {
                  AppFeedback.mediumImpact();
                  await AuthService.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış yap'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppThemeExtension.of(context).danger,
                  side: BorderSide(color: AppThemeExtension.of(context).danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
