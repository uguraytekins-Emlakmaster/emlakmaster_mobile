import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/widgets/client_engagement_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri İlgi & Etkileşim — kaydedilen ilgi ve gerçek etkileşim kanalları
/// (Screen 20). Tab kimliği korunur (client shell index 1 · 'favorites').
/// Yalnızca gerçek sinyaller: auth/profil, önizleme portföy sayımı ve gerçek
/// kabuk sekmesi kanalları. Uydurma analiz/geçmiş yok.
class ClientPortalFavoritesPage extends ConsumerWidget {
  const ClientPortalFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ClientEngagementSurface(),
        ),
      ),
    );
  }
}
