import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_discovery_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_favorites_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_messages_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_profile_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_request_center_page.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/pages/client_portal_virtual_tours_page.dart';
import 'package:flutter/material.dart';

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

/// Müşteri: Mesajlar — premium iletişim kanalları.
class ClientMessagesPage extends StatelessWidget {
  const ClientMessagesPage({super.key});

  @override
  Widget build(BuildContext context) => const ClientPortalMessagesPage();
}

/// Müşteri: Sanal tur — harici örnek içerikler. (Artık alt navigasyonda
/// gösterilmiyor; yeri Talep Merkezi'ne devredildi — sayfa derin bağlantı /
/// gelecekteki kullanım için korunur.)
class ClientVirtualTourPage extends StatelessWidget {
  const ClientVirtualTourPage({super.key});

  @override
  Widget build(BuildContext context) => const ClientPortalVirtualToursPage();
}

/// Müşteri: Talep Merkezi — kayıtlı talepler ve gerçek sonraki adımlar.
class ClientRequestCenterPage extends StatelessWidget {
  const ClientRequestCenterPage({super.key});

  @override
  Widget build(BuildContext context) => const ClientPortalRequestCenterPage();
}

/// Müşteri: Profil — hesap merkezi.
class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const ClientPortalProfilePage();
}
