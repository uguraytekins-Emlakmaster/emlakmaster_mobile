import 'dart:convert';

/// Dış piyasa API’leri için yer tutucu (Endeksa / Sahibinden benzeri).
class ExternalMarketSnapshot {
  const ExternalMarketSnapshot({
    this.avgPricePerM2District,
    this.demandIndexExternal,
    this.sourceLabel,
  });

  final double? avgPricePerM2District;
  /// 0–100 arası talep endeksi (API’den).
  final double? demandIndexExternal;
  final String? sourceLabel;

  bool get hasData =>
      avgPricePerM2District != null || demandIndexExternal != null;
}

/// Rainbow Score alt bileşenleri (0–100 ana skor).
class RainbowScoreBreakdown {
  const RainbowScoreBreakdown({
    required this.roiComponent,
    required this.demandComponent,
    required this.pricePerM2Component,
    required this.amortizationYears,
    required this.districtDemandIndex,
    required this.pricePerM2RatioVsNeighborhood,
  });

  /// Amortisman / getiri bileşeni (0–35).
  final double roiComponent;
  /// Saha-Radar / ilçe talep bileşeni (0–35).
  final double demandComponent;
  /// m² fiyatının mahalle ortalamasına göre bileşeni (0–30).
  final double pricePerM2Component;

  final double amortizationYears;
  /// 0–100
  final double districtDemandIndex;
  /// 1.0 = ortalama; &lt;1 ucuza, &gt;1 pahalı.
  final double pricePerM2RatioVsNeighborhood;

  double get total =>
      roiComponent + demandComponent + pricePerM2Component;
}

/// Isolate ve motor için serileştirilebilir girdi.
class IntelIsolatePayload {
  const IntelIsolatePayload({
    required this.priceTry,
    required this.m2,
    required this.districtAgentCount,
    required this.maxDistrictAgentCount,
    required this.neighborhoodAvgPricePerM2,
    this.monthlyRentTry,
  });

  final double priceTry;
  final double m2;
  final int districtAgentCount;
  final int maxDistrictAgentCount;
  final double neighborhoodAvgPricePerM2;
  final double? monthlyRentTry;
}

/// Motor çıktısı (saf Dart — Isolate uyumlu).
class RainbowScoreResult {
  const RainbowScoreResult({
    required this.score0to100,
    required this.breakdown,
  });

  final double score0to100;
  final RainbowScoreBreakdown breakdown;
}

/// PDF / bölge karşılaştırması — Kayapınar & Bağlar (canlı heatmap veya varsayılan).
class DistrictSnapshotRow {
  const DistrictSnapshotRow({
    required this.districtName,
    required this.demandScore,
    required this.budgetSegment,
    this.propertyTypeHint,
  });

  /// Görünen ad (örn. Kayapınar).
  final String districtName;
  /// 0–1 talep skoru (Market Pulse ile uyumlu).
  final double demandScore;
  final String budgetSegment;
  final String? propertyTypeHint;

  Map<String, dynamic> toJson() => {
        'districtName': districtName,
        'demandScore': demandScore,
        'budgetSegment': budgetSegment,
        'propertyTypeHint': propertyTypeHint,
      };

  factory DistrictSnapshotRow.fromJson(Map<String, dynamic> j) {
    return DistrictSnapshotRow(
      districtName: j['districtName'] as String? ?? '',
      demandScore: (j['demandScore'] as num?)?.toDouble() ?? 0,
      budgetSegment: j['budgetSegment'] as String? ?? '',
      propertyTypeHint: j['propertyTypeHint'] as String?,
    );
  }
}

/// Tam analiz raporu (UI + PDF + geçmiş).
class RainbowIntelReport {
  RainbowIntelReport({
    required this.id,
    required this.generatedAt,
    required this.propertyTitle,
    required this.district,
    required this.listingPriceTry,
    required this.m2,
    required this.rainbowScore,
    required this.breakdown,
    required this.priceTrend12mTryPerM2,
    required this.listingUrl,
    this.listingId,
    this.imageUrl,
    this.districtSnapshots = const [],
  });

  final String id;
  final DateTime generatedAt;
  final String? listingId;
  final String propertyTitle;
  final String district;
  final double listingPriceTry;
  final double m2;
  final double rainbowScore;
  final RainbowScoreBreakdown breakdown;
  /// 12 ay — m² başına TL (gösterim için).
  final List<double> priceTrend12mTryPerM2;
  final String listingUrl;
  final String? imageUrl;
  /// Kayapınar / Bağlar karşılaştırma satırları (PDF grid).
  final List<DistrictSnapshotRow> districtSnapshots;

  double get pricePerM2 => m2 > 0 ? listingPriceTry / m2 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'generatedAt': generatedAt.toIso8601String(),
        'listingId': listingId,
        'propertyTitle': propertyTitle,
        'district': district,
        'listingPriceTry': listingPriceTry,
        'm2': m2,
        'rainbowScore': rainbowScore,
        'breakdown': {
          'roiComponent': breakdown.roiComponent,
          'demandComponent': breakdown.demandComponent,
          'pricePerM2Component': breakdown.pricePerM2Component,
          'amortizationYears': breakdown.amortizationYears,
          'districtDemandIndex': breakdown.districtDemandIndex,
          'pricePerM2RatioVsNeighborhood':
              breakdown.pricePerM2RatioVsNeighborhood,
        },
        'priceTrend12mTryPerM2': priceTrend12mTryPerM2,
        'listingUrl': listingUrl,
        'imageUrl': imageUrl,
        'districtSnapshots':
            districtSnapshots.map((e) => e.toJson()).toList(),
      };

  factory RainbowIntelReport.fromJson(Map<String, dynamic> j) {
    final b = j['breakdown'] as Map<String, dynamic>? ?? {};
    return RainbowIntelReport(
      id: j['id'] as String,
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      listingId: j['listingId'] as String?,
      propertyTitle: j['propertyTitle'] as String,
      district: j['district'] as String,
      listingPriceTry: (j['listingPriceTry'] as num).toDouble(),
      m2: (j['m2'] as num).toDouble(),
      rainbowScore: (j['rainbowScore'] as num).toDouble(),
      breakdown: RainbowScoreBreakdown(
        roiComponent: (b['roiComponent'] as num).toDouble(),
        demandComponent: (b['demandComponent'] as num).toDouble(),
        pricePerM2Component: (b['pricePerM2Component'] as num).toDouble(),
        amortizationYears: (b['amortizationYears'] as num).toDouble(),
        districtDemandIndex: (b['districtDemandIndex'] as num).toDouble(),
        pricePerM2RatioVsNeighborhood:
            (b['pricePerM2RatioVsNeighborhood'] as num).toDouble(),
      ),
      priceTrend12mTryPerM2: (j['priceTrend12mTryPerM2'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      listingUrl: j['listingUrl'] as String,
      imageUrl: j['imageUrl'] as String?,
      districtSnapshots: (j['districtSnapshots'] as List<dynamic>?)
              ?.map((e) => DistrictSnapshotRow.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList() ??
          const [],
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Off-market / manuel giriş.
class CustomIntelInput {
  const CustomIntelInput({
    required this.title,
    required this.district,
    required this.priceTry,
    required this.m2,
    this.monthlyRentTry,
  });

  final String title;
  final String district;
  final double priceTry;
  final double m2;
  final double? monthlyRentTry;
}
