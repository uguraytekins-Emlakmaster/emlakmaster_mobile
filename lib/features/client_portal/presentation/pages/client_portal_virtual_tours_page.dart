import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_secondary_widgets.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientPortalVirtualTourItem {
  const ClientPortalVirtualTourItem({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;
}

const clientPortalSampleTours = <ClientPortalVirtualTourItem>[
  ClientPortalVirtualTourItem(
    title: 'Örnek daire turu',
    subtitle: 'YouTube üzerinde 360° örnek içerik',
    url: 'https://www.youtube.com/results?search_query=360+apartment+tour',
  ),
  ClientPortalVirtualTourItem(
    title: 'Boş dağıtım gezintisi',
    subtitle: 'Mimari sanal tur örneği · harici site',
    url: 'https://www.youtube.com/results?search_query=real+estate+virtual+tour',
  ),
];

/// Müşteri Sanal Tur — harici örnek içerikler, kayıt/izleme yok.
class ClientPortalVirtualToursPage extends StatelessWidget {
  const ClientPortalVirtualToursPage({super.key});

  Future<void> _openTour(BuildContext context, ClientPortalVirtualTourItem tour) async {
    AppFeedback.lightImpact();
    final uri = Uri.parse(tour.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bağlantı açılamadı.')),
    );
  }

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
                  title: 'Sanal tur',
                  subtitle: 'Portföyü uzaktan keşfedin · immersive önizleme',
                  verificationNote:
                      'Bağlantılar harici sitede örnek içerik açar; kayıtlı tur ve izleme geçmişi yakında.',
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
                      ('Harici', 'Açılış'),
                      ('Örnek', 'İçerik'),
                      ('Yakında', 'Kayıt'),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: PremiumClientSectionLabel(
                  label: 'Örnek turlar',
                  secondary: 'Harici tarayıcıda açılır',
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tour = clientPortalSampleTours[index];
                    return ClientVirtualTourCard(
                      title: tour.title,
                      subtitle: tour.subtitle,
                      onTap: () => _openTour(context, tour),
                    );
                  },
                  childCount: clientPortalSampleTours.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    ClientPortalTokens.horizontal,
                    4,
                    ClientPortalTokens.horizontal,
                    dock,
                  ),
                  child: ClientPortalSurface(
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.open_in_browser_rounded,
                              size: 18, color: ext.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tüm turlar harici platformda açılır. '
                              'Gerçek portföy turları danışmanınız paylaştığında burada listelenecek.',
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
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
