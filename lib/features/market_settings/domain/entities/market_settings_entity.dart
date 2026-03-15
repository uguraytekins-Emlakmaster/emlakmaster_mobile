import 'package:equatable/equatable.dart';

/// Diyarbakır bölge baz m2 fiyatı (Price Intelligence referansı).
class RegionBasePrice with EquatableMixin {
  const RegionBasePrice({
    required this.regionId,
    required this.regionName,
    required this.basePricePerSqm,
    this.currency = 'TRY',
    this.updatedAt,
  });

  final String regionId;
  final String regionName;
  final double basePricePerSqm;
  final String currency;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [regionId, basePricePerSqm];
}

/// Market Settings: Diyarbakır ana bölgeleri baz m2 fiyatları.
class MarketSettingsEntity with EquatableMixin {
  const MarketSettingsEntity({
    this.regionBasePrices = const [],
    this.currency = 'TRY',
    this.updatedAt,
  });

  final List<RegionBasePrice> regionBasePrices;
  final String currency;
  final DateTime? updatedAt;

  static const String regionKayapinar = 'kayapinar';
  static const String regionBaglar = 'baglar';
  static const String regionYenisehir = 'yenisehir';

  /// Varsayılan Diyarbakır baz fiyatları (manuel güncellenebilir).
  static List<RegionBasePrice> get defaultDiyarbakirRegions => [
    const RegionBasePrice(regionId: regionKayapinar, regionName: 'Kayapınar', basePricePerSqm: 25000),
    const RegionBasePrice(regionId: regionBaglar, regionName: 'Bağlar', basePricePerSqm: 18000),
    const RegionBasePrice(regionId: regionYenisehir, regionName: 'Yenişehir', basePricePerSqm: 22000),
  ];

  double? basePriceForRegion(String regionId) {
    final r = regionBasePrices.cast<RegionBasePrice?>().firstWhere(
      (e) => e?.regionId == regionId,
      orElse: () => null,
    );
    return r?.basePricePerSqm;
  }

  @override
  List<Object?> get props => [regionBasePrices, currency];
}
