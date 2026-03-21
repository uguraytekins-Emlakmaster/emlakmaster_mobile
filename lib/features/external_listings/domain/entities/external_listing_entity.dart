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

  @override
  List<Object?> get props => [id, source, externalId, title, propertyType, link, postedAt];
}
