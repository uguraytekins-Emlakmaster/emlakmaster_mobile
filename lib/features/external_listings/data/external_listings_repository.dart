import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';

class ExternalListingsRepository {
  static const int defaultLimit = 50;

  static String? _propertyTypeFromDoc(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Şehir (ve isteğe bağlı ilçe) filtresiyle son atılan ilanları stream et.
  /// İlçe filtresi uygulama tarafında uygulanır (tek indeks: cityCode + postedAt).
  static Stream<List<ExternalListingEntity>> streamListings({
    required String cityCode,
    String? districtName,
    int limit = defaultLimit,
  }) async* {
    await FirestoreService.ensureInitialized();
    final q = FirebaseFirestore.instance
        .collection(AppConstants.colExternalListings)
        .where('cityCode', isEqualTo: cityCode)
        .orderBy('postedAt', descending: true)
        .limit(limit);
    yield* q.snapshots().map((snap) {
      var list = snap.docs.map((doc) => _fromDoc(doc)).toList();
      if (districtName != null && districtName.isNotEmpty) {
        list = list.where((e) => e.district == districtName).toList();
      }
      return list;
    });
  }

  static ExternalListingEntity _fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final sourceStr = d['source'] as String? ?? 'sahibinden';
    final source = ExternalListingSource.values.firstWhere(
      (e) => e.name == sourceStr,
      orElse: () => ExternalListingSource.sahibinden,
    );
    final postedAt = d['postedAt'] is Timestamp
        ? (d['postedAt'] as Timestamp).toDate()
        : DateTime.now();
    final ingestedByRaw = d['ingestedBy'];
    final ingestedBy =
        ingestedByRaw is String && ingestedByRaw.trim().isNotEmpty
            ? ingestedByRaw.trim()
            : null;
    return ExternalListingEntity(
      id: doc.id,
      source: source,
      externalId: d['externalId'] as String? ?? doc.id,
      title: d['title'] as String? ?? '',
      propertyType: _propertyTypeFromDoc(d['propertyType']),
      priceText: d['priceText'] as String?,
      priceValue: (d['priceValue'] as num?)?.toDouble(),
      city: d['cityName'] as String? ?? d['cityCode'] as String? ?? '',
      district: d['districtName'] as String?,
      link: d['link'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      postedAt: postedAt,
      roomCount: d['roomCount'] as String?,
      sqm: (d['sqm'] as num?)?.toDouble(),
      trendPct: (d['trendPct'] as num?)?.toDouble(),
      ingestedAt: d['ingestedAt'] is Timestamp
          ? (d['ingestedAt'] as Timestamp).toDate()
          : null,
      ingestedBy: ingestedBy,
    );
  }
}
