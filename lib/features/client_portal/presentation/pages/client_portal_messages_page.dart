import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/widgets/client_portal_messages_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';

/// Müşteri: Mesajlar — premium iletişim masası (Screen 32).
class ClientPortalMessagesPage extends StatelessWidget {
  const ClientPortalMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ClientPortalMessagesSurface(),
        ),
      ),
    );
  }
}
