import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';

enum ClientListingKind { sale, rent }

enum ClientPortalFilter {
  all,
  sale,
  rent,
  favorites,
  newListings,
  recommended,
}

extension ClientPortalFilterLabels on ClientPortalFilter {
  String get label => switch (this) {
        ClientPortalFilter.all => 'Tümü',
        ClientPortalFilter.sale => 'Satılık',
        ClientPortalFilter.rent => 'Kiralık',
        ClientPortalFilter.favorites => 'Favoriler',
        ClientPortalFilter.newListings => 'Yeni',
        ClientPortalFilter.recommended => 'Önerilen',
      };
}

enum ClientPortalMessageState { preview, ready }

enum ClientPortalAppointmentState { preview, ready }

class ClientPortalSummary {
  const ClientPortalSummary({
    required this.favoriteCount,
    required this.portfolioPreviewCount,
    required this.messageState,
    required this.appointmentState,
    required this.profileReady,
  });

  final int favoriteCount;
  final int portfolioPreviewCount;
  final ClientPortalMessageState messageState;
  final ClientPortalAppointmentState appointmentState;
  final bool profileReady;

  static ClientPortalSummary fromAuth({required bool signedIn}) {
    return ClientPortalSummary(
      favoriteCount: 0,
      portfolioPreviewCount: clientPortalPreviewCatalog.length,
      messageState: ClientPortalMessageState.preview,
      appointmentState: ClientPortalAppointmentState.preview,
      profileReady: signedIn,
    );
  }
}

ClientPortalSummary computeClientPortalSummary({required bool signedIn}) {
  return ClientPortalSummary.fromAuth(signedIn: signedIn);
}

bool matchesClientPortalFilter(
  ClientPortalPreviewListing row,
  ClientPortalFilter filter,
  String searchQuery,
) {
  if (!_matchesSearch(row, searchQuery)) return false;
  return switch (filter) {
    ClientPortalFilter.all => true,
    ClientPortalFilter.sale => row.kind == ClientListingKind.sale,
    ClientPortalFilter.rent => row.kind == ClientListingKind.rent,
    ClientPortalFilter.favorites => false,
    ClientPortalFilter.newListings => row.isNew,
    ClientPortalFilter.recommended => row.isRecommended,
  };
}

bool _matchesSearch(ClientPortalPreviewListing row, String query) {
  if (query.trim().isEmpty) return true;
  final q = query.toLowerCase();
  bool hit(String? s) => s != null && s.toLowerCase().contains(q);
  return hit(row.title) ||
      hit(row.location) ||
      hit(row.features) ||
      hit(row.priceLabel);
}
