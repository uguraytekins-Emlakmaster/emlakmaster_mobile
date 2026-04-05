import 'package:equatable/equatable.dart';

/// Ayarlar: şehir, ilçe, şirket adı, logo (Market Pulse ilan kaynakları & ofis).
class ListingDisplaySettingsEntity with EquatableMixin {
  const ListingDisplaySettingsEntity({
    this.cityCode = '21',
    this.cityName = 'Diyarbakır',
    this.districtCode,
    this.districtName,
    this.companyName = '',
    this.logoUrl,
    this.updatedAt,
  });

  final String cityCode;
  final String cityName;
  final String? districtCode;
  final String? districtName;
  final String companyName;
  final String? logoUrl;
  final DateTime? updatedAt;

  ListingDisplaySettingsEntity copyWith({
    String? cityCode,
    String? cityName,
    String? districtCode,
    String? districtName,
    String? companyName,
    String? logoUrl,
    DateTime? updatedAt,
    bool clearDistrict = false,
    bool clearLogo = false,
  }) {
    return ListingDisplaySettingsEntity(
      cityCode: cityCode ?? this.cityCode,
      cityName: cityName ?? this.cityName,
      districtCode: clearDistrict ? null : (districtCode ?? this.districtCode),
      districtName: clearDistrict ? null : (districtName ?? this.districtName),
      companyName: companyName ?? this.companyName,
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [cityCode, cityName, districtCode, districtName, companyName, logoUrl];
}
