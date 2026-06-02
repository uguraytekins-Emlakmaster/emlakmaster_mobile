import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/client_portal_messages_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/client_portal_messages_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/widgets/client_portal_messages_channel_tile.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/widgets/client_portal_messages_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_secondary_widgets.dart';
import 'package:flutter/material.dart';

/// Müşteri Mesajlar komuta yüzeyi (Screen 32) — premium, dürüst, hızlı.
class ClientPortalMessagesSurface extends StatelessWidget {
  const ClientPortalMessagesSurface({super.key});

  double _dockReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return ClientPortalMessagesTokens.bottomReserve * ratio.clamp(1.0, 1.38);
  }

  VoidCallback _actionFor(ClientMessagesChannelKind kind) {
    return switch (kind) {
      ClientMessagesChannelKind.whatsApp =>
        () => ClientPortalContactActions.openWhatsApp(),
      ClientMessagesChannelKind.phone =>
        () => ClientPortalContactActions.openPhone(),
      ClientMessagesChannelKind.email =>
        () => ClientPortalContactActions.openEmail(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dock = _dockReserve(context);

    return CustomScrollView(
      cacheExtent: 320,
      slivers: [
        const SliverToBoxAdapter(child: ClientMessagesConciergeHeader()),
        const SliverToBoxAdapter(
          child: ClientMessagesTrustStrip(cells: clientMessagesTrustCells),
        ),
        const SliverToBoxAdapter(
          child: ClientMessagesSectionLabel(
            label: 'İletişim kanalları',
            secondary: 'Dokunduğunuzda ne olacağını bilirsiniz',
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final spec = clientMessagesChannelCatalog[index];
              return ClientMessagesChannelTile(
                spec: spec,
                onTap: _actionFor(spec.kind),
              );
            },
            childCount: clientMessagesChannelCatalog.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ClientPortalMessagesTokens.horizontal,
              4,
              ClientPortalMessagesTokens.horizontal,
              dock,
            ),
            child: const ClientMessagesReassuranceNote(),
          ),
        ),
      ],
    );
  }
}
