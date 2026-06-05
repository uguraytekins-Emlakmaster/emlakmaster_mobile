import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:flutter/material.dart';

enum ClientListingStatusTone { preview, newListing, recommended }

class ClientListingRowSnapshot {
  const ClientListingRowSnapshot({
    required this.statusLabel,
    required this.statusTone,
    required this.kindLabel,
    required this.canFavorite,
    required this.canMessage,
    required this.canAppointment,
    required this.canShare,
    required this.canInspect,
  });

  final String statusLabel;
  final ClientListingStatusTone statusTone;
  final String kindLabel;
  final bool canFavorite;
  final bool canMessage;
  final bool canAppointment;
  final bool canShare;
  final bool canInspect;

  factory ClientListingRowSnapshot.fromPreview(ClientPortalPreviewListing row) {
    final status = row.isRecommended
        ? ('Önerilen', ClientListingStatusTone.recommended)
        : row.isNew
            ? ('Yeni', ClientListingStatusTone.newListing)
            : ('Önizleme', ClientListingStatusTone.preview);

    return ClientListingRowSnapshot(
      statusLabel: status.$1,
      statusTone: status.$2,
      kindLabel: row.kind == ClientListingKind.sale ? 'Satılık' : 'Kiralık',
      canFavorite: false,
      canMessage: true,
      canAppointment: false,
      canShare: true,
      canInspect: true,
    );
  }

  Color toneColor(ClientListingStatusTone tone, Color accent, Color info, Color success) {
    return switch (tone) {
      ClientListingStatusTone.preview => info,
      ClientListingStatusTone.newListing => success,
      ClientListingStatusTone.recommended => accent,
    };
  }
}
