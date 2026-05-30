import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_secondary_widgets.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri Profil — hesap merkezi (gerçek auth + bilgilendirme).
class ClientPortalProfilePage extends ConsumerWidget {
  const ClientPortalProfilePage({super.key});

  void _showPrivacy(BuildContext context) {
    AppFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('KVKK & Gizlilik'),
        content: const SingleChildScrollView(
          child: Text(
            'Kişisel verileriniz yalnızca hizmet sunumu ve yasal yükümlülükler kapsamında işlenir. '
            'Detaylı bilgi için ofisimizle iletişime geçebilirsiniz.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    AppFeedback.selectionClick();
    final version = AppConstants.appVersion.split('+').first;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppConstants.appName),
        content: Text(
          'Sürüm $version\n\n'
          'Müşteri portalı — portföy keşfi, iletişim ve hesap yönetimi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final signedIn = user != null;
    final ext = AppThemeExtension.of(context);
    final dock = clientPortalDockBottomReserve(context);
    final version = AppConstants.appVersion.split('+').first;

    final avatarLetter = () {
      final label = user?.email ?? user?.displayName ?? 'M';
      return label.isNotEmpty ? label[0].toUpperCase() : '?';
    }();

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PremiumClientPortalHeader(
                  title: 'Hesabım',
                  subtitle: 'Profil · gizlilik · destek',
                  verificationNote: signedIn
                      ? 'Hesap oturumunuz güvenli şekilde yönetilir.'
                      : 'Giriş yaparak kişisel portföy deneyiminizi sürdürün.',
                  actions: signedIn
                      ? const [
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: SessionAvatarButton(size: 38),
                          ),
                        ]
                      : const [],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: ClientPortalTokens.chromeGap,
                    bottom: ClientPortalTokens.chromeGap,
                  ),
                  child: ClientCompactInfoStrip(
                    cells: [
                      (signedIn ? 'Aktif' : '—', 'Hesap'),
                      ('Müşteri', 'Rol'),
                      (version, 'Sürüm'),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClientPortalTokens.horizontal,
                  ),
                  child: ClientPortalSurface(
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                ext.accent.withValues(alpha: 0.18),
                            child: Text(
                              avatarLetter,
                              style: TextStyle(
                                color: ext.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? 'Giriş yapılmamış',
                                  style: TextStyle(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  signedIn
                                      ? 'Müşteri hesabı · oturum açık'
                                      : 'Oturum kapalı · keşfetmeye devam edebilirsiniz',
                                  style: TextStyle(
                                    color: ext.textSecondary,
                                    fontSize: 11.5,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: PremiumClientSectionLabel(
                  label: 'Hesap & gizlilik',
                  secondary: 'Bilgilendirme',
                ),
              ),
              SliverToBoxAdapter(
                child: ClientProfileMenuRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'KVKK & Gizlilik',
                  subtitle: 'Verileriniz nasıl kullanılır?',
                  onTap: () => _showPrivacy(context),
                ),
              ),
              SliverToBoxAdapter(
                child: ClientProfileMenuRow(
                  icon: Icons.verified_user_outlined,
                  title: 'Hesap durumu',
                  subtitle: signedIn
                      ? 'Oturum aktif · güvenli bağlantı'
                      : 'Giriş yapılmamış',
                  trailing: Icon(
                    signedIn ? Icons.check_circle_rounded : Icons.info_outline,
                    color: signedIn ? ext.success : ext.textTertiary,
                    size: 20,
                  ),
                  onTap: () {
                    AppFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          signedIn
                              ? 'Hesabınız aktif. Çıkış yapmak için aşağıdaki düğmeyi kullanın.'
                              : 'Giriş yapmadan keşfet ve iletişim kanallarını kullanabilirsiniz.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: PremiumClientSectionLabel(
                  label: 'Destek',
                  secondary: 'Yardım ve iletişim',
                ),
              ),
              SliverToBoxAdapter(
                child: ClientProfileMenuRow(
                  icon: Icons.support_agent_rounded,
                  title: 'Yardım & Destek',
                  subtitle: 'İletişim kanallarına git',
                  onTap: () {
                    AppFeedback.selectionClick();
                    ref
                        .read(mainShellShortcutProvider.notifier)
                        .enqueue(MainShellShortcut.openMessagesTab);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: PremiumClientSectionLabel(
                  label: 'Uygulama',
                  secondary: AppConstants.appName,
                ),
              ),
              SliverToBoxAdapter(
                child: ClientProfileMenuRow(
                  icon: Icons.info_outline_rounded,
                  title: 'Uygulama bilgisi',
                  subtitle: 'Sürüm $version · bilgilendirme',
                  onTap: () => _showAbout(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    ClientPortalTokens.horizontal,
                    8,
                    ClientPortalTokens.horizontal,
                    dock,
                  ),
                  child: signedIn
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            AppFeedback.mediumImpact();
                            await AuthService.instance.signOut();
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Çıkış yap'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ext.danger,
                            side: BorderSide(color: ext.danger),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      : ClientPortalSurface(
                          padding: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Hesap tercihleri ve gelişmiş profil ayarları yakında aktif olacak.',
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
