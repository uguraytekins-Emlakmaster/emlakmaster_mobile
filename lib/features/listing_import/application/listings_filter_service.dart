import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';

/// UI’dan bağımsız filtreleme (test edilebilir).
abstract final class ListingsFilterService {
  ListingsFilterService._();

  static List<ListingEntity> apply(
    List<ListingEntity> items, {
    String? platformId,
    double? minPrice,
    double? maxPrice,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool favoritesOnly = false,
    String? duplicateGroupId,
  }) {
    var out = items;
    if (platformId != null && platformId.isNotEmpty) {
      out = out.where((e) => e.platformId == platformId).toList();
    }
    if (minPrice != null) {
      out = out.where((e) => e.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      out = out.where((e) => e.price <= maxPrice).toList();
    }
    if (createdAfter != null) {
      out = out.where((e) => !e.createdAt.isBefore(createdAfter)).toList();
    }
    if (createdBefore != null) {
      final end = DateTime(createdBefore.year, createdBefore.month, createdBefore.day, 23, 59, 59);
      out = out.where((e) => !e.createdAt.isAfter(end)).toList();
    }
    if (favoritesOnly) {
      out = out.where((e) => e.isFavorite).toList();
    }
    if (duplicateGroupId != null && duplicateGroupId.isNotEmpty) {
      out = out.where((e) => e.duplicateGroupId == duplicateGroupId).toList();
    }
    return out;
  }

  /// duplicateGroupId → tüm üyeler
  static Map<String, List<ListingEntity>> groupByDuplicate(List<ListingEntity> items) {
    final map = <String, List<ListingEntity>>{};
    for (final e in items) {
      final g = e.duplicateGroupId;
      if (g == null || g.isEmpty) continue;
      map.putIfAbsent(g, () => []).add(e);
    }
    return map;
  }
}
