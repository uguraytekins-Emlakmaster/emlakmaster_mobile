import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';

/// Önizleme portföy satırı — gerçek müşteri verisi değil; UI kanıtı için.
class ClientPortalPreviewListing {
  const ClientPortalPreviewListing({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.location,
    required this.features,
    required this.kind,
    this.isNew = false,
    this.isRecommended = false,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String location;
  final String features;
  final ClientListingKind kind;
  final bool isNew;
  final bool isRecommended;
}

/// Statik önizleme katalog — backend bağlantısı yok.
const clientPortalPreviewCatalog = <ClientPortalPreviewListing>[
  ClientPortalPreviewListing(
    id: 'preview-1',
    title: '3+1 Daire · Kayapınar',
    priceLabel: '4.850.000 ₺',
    location: 'Kayapınar, Diyarbakır',
    features: '145 m² · 3+1 · Asansör',
    kind: ClientListingKind.sale,
    isNew: true,
    isRecommended: true,
  ),
  ClientPortalPreviewListing(
    id: 'preview-2',
    title: '2+1 Kiralık · Yenişehir',
    priceLabel: '22.000 ₺ / ay',
    location: 'Yenişehir, Diyarbakır',
    features: '95 m² · 2+1 · Eşyalı',
    kind: ClientListingKind.rent,
    isRecommended: true,
  ),
  ClientPortalPreviewListing(
    id: 'preview-3',
    title: 'İmarlı Arsa · Bağlar',
    priceLabel: '2.400.000 ₺',
    location: 'Bağlar, Diyarbakır',
    features: '420 m² · Yola cephe',
    kind: ClientListingKind.sale,
    isNew: true,
  ),
  ClientPortalPreviewListing(
    id: 'preview-4',
    title: 'Lüks Villa · Sur',
    priceLabel: '12.500.000 ₺',
    location: 'Sur, Diyarbakır',
    features: '320 m² · 5+2 · Havuz',
    kind: ClientListingKind.sale,
    isRecommended: true,
  ),
];
