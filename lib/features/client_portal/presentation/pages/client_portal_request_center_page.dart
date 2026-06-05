import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/widgets/request_center_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri Talep Merkezi — kayıtlı talepler ve gerçek sonraki adım kanalları
/// (Screen 23). Client shell index 3 ('requests'). Yalnızca gerçek sinyaller:
/// auth/profil ve gerçek kabuk sekmesi/iletişim kanalları. Sunucuda tutulan
/// kayıtlı talep verisi olmadığından uydurma talep/durum/eşleşme gösterilmez.
class ClientPortalRequestCenterPage extends ConsumerWidget {
  const ClientPortalRequestCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RequestCenterSurface(),
        ),
      ),
    );
  }
}
