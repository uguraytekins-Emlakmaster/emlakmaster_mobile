import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';

/// Senkron / içe aktarma durumu (Firestore `syncStatus` ile uyumlu).
enum ListingSyncStatus {
  synced,
  pending,
  error,
  stale,
  unknown,
}

/// Ofisin kontrolündeki ilan mı, yoksa pazar / üçüncü taraf akışı mı.
enum ListingSurface {
  /// `listings` veya resmi senkron (`integration_listings`) — ofis envanteri.
  owned,

  /// Resmi pazar akışı (`external_listings` + ingest). Birinci şahıs envanter değildir.
  marketFeed,
}

/// İlanlar sekmesinde tek kart satırı — zorunlu meta alanlar.
class ListingRowView {
  const ListingRowView({
    required this.id,
    required this.sourcePlatform,
    required this.sourceListingId,
    required this.isOwnedByOffice,
    required this.syncStatus,
    this.lastSyncedAt,
    this.contentHash,
    required this.title,
    required this.priceLabel,
    required this.locationLabel,
    this.imageUrl,
    required this.surface,
    required this.rowKind,
    this.openInBrowserUrl,
    this.detailListingId,
    this.integrationDocId,
  });

  /// Firestore doküman veya sentetik anahtar.
  final String id;

  /// Örn. `internal`, `sahibinden`, `emlakjet`, `hepsiemlak`, `market_sahibinden`
  final String sourcePlatform;

  /// Kaynak sistemdeki ilan kimliği.
  final String sourceListingId;

  /// Ofisin birinci şahıs envanteri (iç + resmi senkron).
  final bool isOwnedByOffice;

  final ListingSyncStatus syncStatus;
  final DateTime? lastSyncedAt;

  /// İçerik bütünlüğü / dedup için (opsiyonel).
  final String? contentHash;

  final String title;
  final String priceLabel;
  final String locationLabel;
  final String? imageUrl;

  final ListingSurface surface;

  /// Arayüzde bölüm ayırma: iç portföy vs bağlı platform senkronu.
  final ListingRowKind rowKind;

  final String? openInBrowserUrl;

  /// Yerel detay sayfası (`/listing/:id`) — iç ilanlar.
  final String? detailListingId;

  /// `integration_listings` doküman id (debug / gelecek kullanım).
  final String? integrationDocId;
}

/// "Benim İlanlarım" / pazar sekmesi içinde görsel ayrım.
enum ListingRowKind {
  officePortfolio,
  connectedPlatform,
  market,
}

String listingSyncStatusLabel(ListingSyncStatus s) {
  switch (s) {
    case ListingSyncStatus.synced:
      return 'Senkron';
    case ListingSyncStatus.pending:
      return 'Bekliyor';
    case ListingSyncStatus.error:
      return 'Hata';
    case ListingSyncStatus.stale:
      return 'Güncellenmeli';
    case ListingSyncStatus.unknown:
      return '—';
  }
}

String sourcePlatformDisplayLabel(String sourcePlatform, {IntegrationPlatformId? platform}) {
  if (platform != null) return platform.displayName;
  switch (sourcePlatform) {
    case 'internal':
    case 'portfolio':
      return 'Ofis portföyü';
    case 'import':
    case 'import_file':
      return 'Dosya içe aktarma';
    case 'import_csv':
      return 'CSV içe aktarma';
    case 'import_json':
      return 'JSON içe aktarma';
    case 'import_xlsx':
      return 'Excel içe aktarma';
    case 'import_xml':
      return 'XML içe aktarma';
    default:
      if (sourcePlatform.startsWith('market_')) {
        return 'Pazar · ${sourcePlatform.replaceFirst('market_', '')}';
      }
      return sourcePlatform;
  }
}

ListingSyncStatus parseListingSyncStatus(String? raw) {
  switch (raw) {
    case 'synced':
      return ListingSyncStatus.synced;
    case 'pending':
      return ListingSyncStatus.pending;
    case 'error':
      return ListingSyncStatus.error;
    case 'stale':
      return ListingSyncStatus.stale;
    default:
      return ListingSyncStatus.unknown;
  }
}
