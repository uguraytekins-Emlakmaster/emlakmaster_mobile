import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/crm_customers/data/customer_mapper.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toplu kampanya filtre modeli.
class BulkCampaignFilters {
  const BulkCampaignFilters({
    required this.minBudgetMillions,
    required this.maxBudgetMillions,
    required this.minLeadTemperature,
    required this.requireRecentInteraction,
    required this.requireNoRecentInteraction,
    required this.regionQuery,
  });

  final double minBudgetMillions;
  final double maxBudgetMillions;
  final double minLeadTemperature;
  final bool requireRecentInteraction;
  final bool requireNoRecentInteraction;
  final String regionQuery;

  BulkCampaignFilters copyWith({
    double? minBudgetMillions,
    double? maxBudgetMillions,
    double? minLeadTemperature,
    bool? requireRecentInteraction,
    bool? requireNoRecentInteraction,
    String? regionQuery,
  }) {
    return BulkCampaignFilters(
      minBudgetMillions: minBudgetMillions ?? this.minBudgetMillions,
      maxBudgetMillions: maxBudgetMillions ?? this.maxBudgetMillions,
      minLeadTemperature: minLeadTemperature ?? this.minLeadTemperature,
      requireRecentInteraction:
          requireRecentInteraction ?? this.requireRecentInteraction,
      requireNoRecentInteraction:
          requireNoRecentInteraction ?? this.requireNoRecentInteraction,
      regionQuery: regionQuery ?? this.regionQuery,
    );
  }
}

class BulkCampaignSegment {
  const BulkCampaignSegment({
    required this.name,
    required this.customers,
  });

  final String name;
  final List<CustomerEntity> customers;

  int get activePhonesCount =>
      customers.where((c) => (c.primaryPhone ?? '').trim().isNotEmpty).length;

  List<String> get phones => customers
      .map((e) => e.primaryPhone)
      .whereType<String>()
      .where((p) => p.trim().isNotEmpty)
      .toList();
}

const _defaultFilters = BulkCampaignFilters(
  minBudgetMillions: 1,
  maxBudgetMillions: 10,
  minLeadTemperature: 0.4,
  requireRecentInteraction: true,
  requireNoRecentInteraction: false,
  regionQuery: '',
);

const _defaultMessage =
    'Merhaba, portföyümüzde bütçenize ve tercih ettiğiniz bölgeye uygun yeni ilanlar oluştu. '
    'İsterseniz bugün kısa bir telefonla üzerinden birlikte geçebiliriz.';

class BulkCampaignFiltersNotifier extends Notifier<BulkCampaignFilters> {
  @override
  BulkCampaignFilters build() => _defaultFilters;

  void apply(BulkCampaignFilters filters) {
    state = filters;
  }
}

class BulkCampaignMessageNotifier extends Notifier<String> {
  @override
  String build() => _defaultMessage;

  void setMessage(String value) {
    state = value;
  }
}

/// Sayfa yaşam döngüsü boyunca canlı — autoDispose yok (dispose sırasında state yazımı yok).
final bulkCampaignFiltersProvider =
    NotifierProvider<BulkCampaignFiltersNotifier, BulkCampaignFilters>(
  BulkCampaignFiltersNotifier.new,
);

final bulkCampaignMessageProvider =
    NotifierProvider<BulkCampaignMessageNotifier, String>(
  BulkCampaignMessageNotifier.new,
);

BulkCampaignSegment _segmentFromSnapshot(
  List<CustomerEntity> customers,
  BulkCampaignFilters filters,
) {
  final now = DateTime.now();
  final minBudget = filters.minBudgetMillions * 1000000;
  final maxBudget = filters.maxBudgetMillions * 1000000;

  final filtered = customers.where((c) {
    final phone = (c.primaryPhone ?? '').trim();
    if (phone.isEmpty) return false;

    final temp = c.leadTemperature ?? 0;
    if (temp < filters.minLeadTemperature) return false;

    final last = c.lastInteractionAt ?? c.updatedAt;
    final diffDays = now.difference(last).inDays;

    if (filters.requireRecentInteraction && diffDays > 30) {
      return false;
    }
    if (filters.requireNoRecentInteraction && diffDays <= 45) {
      return false;
    }

    if (filters.regionQuery.trim().isNotEmpty) {
      final q = filters.regionQuery.trim().toLowerCase();
      final regions = c.regionPreferences.map((e) => e.toLowerCase()).toList();
      if (!regions.any((r) => r.contains(q))) return false;
    }

    final bMin = c.budgetMin;
    final bMax = c.budgetMax;
    if (bMin != null || bMax != null) {
      final low = bMin ?? bMax ?? 0;
      final high = bMax ?? bMin ?? low;
      if (high < minBudget) return false;
      if (low > maxBudget) return false;
    }

    return true;
  }).toList();

  return BulkCampaignSegment(
    name: 'Filtrelenmiş CRM segmenti',
    customers: filtered,
  );
}

/// Filtre + Firestore — autoDispose kaldırıldı; dispose sonrası filter state yazımı engellendi.
final bulkCampaignSegmentProvider = StreamProvider<BulkCampaignSegment>((ref) {
  final filters = ref.watch(bulkCampaignFiltersProvider);
  return FirestoreService.customersStream().map((snap) {
    final customers = snap.docs
        .map((d) => CustomerMapper.fromDoc(d))
        .whereType<CustomerEntity>()
        .toList();
    return _segmentFromSnapshot(customers, filters);
  });
});
