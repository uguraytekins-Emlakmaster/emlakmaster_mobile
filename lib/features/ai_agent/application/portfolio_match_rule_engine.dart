import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Kural tabanlı müşteri ↔ portföy eşleştirme.
///
/// Dil disiplini: "Bu portföy uygun olabilir." — ASLA "kesin alır",
/// "kesin satış olur", "yüksek ihtimalle alacak" gibi ifadeler kullanılmaz.
abstract final class PortfolioMatchRuleEngine {
  static List<PortfolioMatchSuggestion> match({
    required AxionCustomerSnapshot customer,
    required List<AxionListingSnapshot> listings,
    int maxResults = AxionAgentPolicy.maxPortfolioMatchesPerCustomer,
  }) {
    final results = <({PortfolioMatchSuggestion s, int strength})>[];

    final capped = listings
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .where((l) => l.isActive);

    for (final listing in capped) {
      final reasons = <String>[];
      var strength = 0;

      // Bölge eşleşmesi = güçlü
      if (customer.hasRegion &&
          (listing.region ?? '').trim().isNotEmpty &&
          _norm(listing.region!) == _norm(customer.region!)) {
        reasons.add('Bölge eşleşiyor (${listing.region})');
        strength += 3;
      }

      // Fiyat aralıkta = güçlü
      if (customer.hasBudget && listing.price != null) {
        final min = customer.budgetMin ?? 0;
        final max = customer.budgetMax ?? double.maxFinite;
        if (listing.price! >= min && listing.price! <= max) {
          reasons.add('Fiyat bütçe aralığında');
          strength += 3;
        }
      }

      // Mülk tipi = güçlü
      if (customer.hasPropertyType &&
          (listing.propertyType ?? '').trim().isNotEmpty &&
          _norm(listing.propertyType!) == _norm(customer.propertyType!)) {
        reasons.add('Mülk tipi eşleşiyor (${listing.propertyType})');
        strength += 3;
      }

      // Oda sayısı = orta
      if (customer.roomCount != null &&
          listing.roomCount != null &&
          customer.roomCount == listing.roomCount) {
        reasons.add('Oda sayısı eşleşiyor');
        strength += 2;
      }

      // Niyet = orta (satılık/kiralık vb. status üzerinden)
      if (customer.hasIntent &&
          (listing.status ?? '').trim().isNotEmpty &&
          _norm(listing.status!).contains(_norm(customer.intent!))) {
        reasons.add('İlan durumu niyetle uyumlu');
        strength += 2;
      }

      if (reasons.isEmpty) continue;

      final missing = <String>[
        if (!customer.hasBudget) 'bütçe',
        if (!customer.hasRegion) 'bölge',
        if (!customer.hasPropertyType) 'mülk tipi',
      ];

      // Güven: veri tamlığına dayalı — eksik bütçe/bölge güveni düşürür.
      final confidence = missing.isEmpty && strength >= 6
          ? AxionAgentConfidence.high
          : missing.length >= 2
              ? AxionAgentConfidence.low
              : AxionAgentConfidence.medium;

      results.add((
        s: PortfolioMatchSuggestion(
          listingId: listing.id,
          customerId: customer.id,
          matchReasons: reasons,
          missingFields: missing,
          confidence: confidence,
          honestyNote: missing.isEmpty
              ? 'Bu portföy uygun olabilir.'
              : 'Bu portföy uygun olabilir. ${AxionAgentPolicy.partialDataNote}',
        ),
        strength: strength,
      ));
    }

    results.sort((a, b) => b.strength.compareTo(a.strength));
    return results.take(maxResults).map((r) => r.s).toList(growable: false);
  }

  static String _norm(String s) => s.trim().toLowerCase();
}
