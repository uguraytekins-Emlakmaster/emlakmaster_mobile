import 'package:equatable/equatable.dart';

/// Harici ilan kaynağı: sahibinden, emlakjet, hepsi emlak.
enum ExternalListingSource {
  sahibinden('sahibinden.com'),
  emlakjet('emlakjet'),
  hepsiEmlak('hepsi emlak'),

  /// Uygulama içi örnek / test (Cloudflare nedeniyle otomatik çekme çalışmazsa).
  demo('örnek');

  const ExternalListingSource(this.label);
  final String label;
}

/// Tekil harici ilan (Market Pulse – son atılan ilanlar).
class ExternalListingEntity with EquatableMixin {
  const ExternalListingEntity({
    required this.id,
    required this.source,
    required this.externalId,
    required this.title,
    this.propertyType,
    this.priceText,
    this.priceValue,
    required this.city,
    this.district,
    required this.link,
    this.imageUrl,
    required this.postedAt,
    this.roomCount,
    this.sqm,

    /// Son dönem fiyat değişimi % (GitHub ingest veya rollup; yoksa null).
    this.trendPct,

    /// Sunucu/CI ingest zamanı (GitHub Actions, CSV vb.).
    this.ingestedAt,
    this.ingestedBy,
  });

  final String id;
  final ExternalListingSource source;
  final String externalId;
  final String title;

  /// Örn. «Konut», «Arsa», «İşyeri» — başlık satırında rozet olarak gösterilir.
  final String? propertyType;
  final String? priceText;
  final double? priceValue;
  final String city;
  final String? district;
  final String link;
  final String? imageUrl;
  final DateTime postedAt;
  final String? roomCount;
  final double? sqm;
  final double? trendPct;
  final DateTime? ingestedAt;
  final String? ingestedBy;

  /// Liste içinde en son ingest (panelde «son senkron» için).
  static DateTime? latestIngestTime(Iterable<ExternalListingEntity> list) {
    DateTime? best;
    for (final e in list) {
      final t = e.ingestedAt;
      if (t != null && (best == null || t.isAfter(best))) {
        best = t;
      }
    }
    return best;
  }

  /// En güncel [ingestedAt] satırının [ingestedBy] değeri (tek kaynak etiketi için).
  static String? ingestSourceAtLatestTime(
      Iterable<ExternalListingEntity> list) {
    DateTime? bestT;
    String? src;
    for (final e in list) {
      final t = e.ingestedAt;
      if (t != null && (bestT == null || t.isAfter(bestT))) {
        bestT = t;
        src = e.ingestedBy;
      }
    }
    return src;
  }

  @override
  List<Object?> get props => [
        id,
        source,
        externalId,
        title,
        propertyType,
        link,
        postedAt,
        trendPct,
        ingestedAt,
        ingestedBy
      ];
}
