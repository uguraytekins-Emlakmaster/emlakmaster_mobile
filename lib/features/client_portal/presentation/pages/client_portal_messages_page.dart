import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_secondary_widgets.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';

/// Müşteri İletişim — premium contact channels (url_launcher only).
class ClientPortalMessagesPage extends StatelessWidget {
  const ClientPortalMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final dock = clientPortalDockBottomReserve(context);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: PremiumClientPortalHeader(
                  title: 'İletişim',
                  subtitle: 'Danışmanınızla güvenli ve hızlı bağlantı',
                  verificationNote:
                      'Uygulama içi mesaj geçmişi henüz aktif değil; kanallar doğrudan danışmanınıza ulaştırır.',
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: ClientPortalTokens.chromeGap,
                    bottom: ClientPortalTokens.chromeGap,
                  ),
                  child: ClientCompactInfoStrip(
                    cells: [
                      ('WhatsApp', 'En hızlı'),
                      ('Doğrudan', 'Kanal'),
                      ('—', 'Geçmiş'),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: PremiumClientSectionLabel(
                  label: 'İletişim kanalları',
                  secondary: 'Aşağıdaki kanallardan birini seçin',
                ),
              ),
              const SliverToBoxAdapter(
                child: ClientContactChannelTile(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp ile yazın',
                  subtitle:
                      'Hızlı mesaj için WhatsApp açılır · yanıt süresi danışmanınıza bağlıdır',
                  highlightLabel: 'En hızlı kanal',
                  accent: Color(0xFF25D366),
                  onTap: ClientPortalContactActions.openWhatsApp,
                ),
              ),
              const SliverToBoxAdapter(
                child: ClientContactChannelTile(
                  icon: Icons.phone_rounded,
                  title: 'Telefon',
                  subtitle: 'Ofis hattını arayın · mesai saatlerinde yanıt',
                  onTap: ClientPortalContactActions.openPhone,
                ),
              ),
              const SliverToBoxAdapter(
                child: ClientContactChannelTile(
                  icon: Icons.email_rounded,
                  title: 'E-posta',
                  subtitle: 'info@rainbowgayrimenkul.com (örnek) · resmi talepler',
                  onTap: ClientPortalContactActions.openEmail,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    ClientPortalTokens.horizontal,
                    6,
                    ClientPortalTokens.horizontal,
                    dock,
                  ),
                  child: ClientPortalSurface(
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Danışmanınızla en hızlı iletişim için aşağıdaki kanalları kullanın. '
                        'Uygulama içi sohbet ve mesaj arşivi yakında aktif olacak.',
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
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
