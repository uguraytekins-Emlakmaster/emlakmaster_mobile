import 'package:emlakmaster_mobile/features/ai_agent/application/portfolio_match_rule_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fullCustomer = AxionCustomerSnapshot(
    id: 'c1',
    name: 'Ali',
    region: 'Kadıköy',
    budgetMin: 1000000,
    budgetMax: 3000000,
    propertyType: 'daire',
    roomCount: 3,
  );

  const matchingListing = AxionListingSnapshot(
    id: 'l1',
    title: 'Kadıköy 3+1',
    region: 'Kadıköy',
    price: 2500000,
    propertyType: 'daire',
    roomCount: 3,
  );

  group('PortfolioMatchRuleEngine', () {
    test('bölge + bütçe + tip eşleşmesi yüksek güven döner', () {
      final matches = PortfolioMatchRuleEngine.match(
        customer: fullCustomer,
        listings: const [matchingListing],
      );
      expect(matches, hasLength(1));
      final m = matches.first;
      expect(m.confidence, AxionAgentConfidence.high);
      expect(m.matchReasons, contains('Bölge eşleşiyor (Kadıköy)'));
      expect(m.matchReasons, contains('Fiyat bütçe aralığında'));
      expect(m.matchReasons, contains('Mülk tipi eşleşiyor (daire)'));
    });

    test('eksik bütçe güveni düşürür ve missingFields listeler', () {
      const noBudget = AxionCustomerSnapshot(
        id: 'c2',
        name: 'Ayşe',
        region: 'Kadıköy',
        propertyType: 'daire',
      );
      final matches = PortfolioMatchRuleEngine.match(
        customer: noBudget,
        listings: const [matchingListing],
      );
      expect(matches, hasLength(1));
      expect(matches.first.confidence, isNot(AxionAgentConfidence.high));
      expect(matches.first.missingFields, contains('bütçe'));
    });

    test('dil disiplini: "uygun olabilir" der, "kesin" demez', () {
      final matches = PortfolioMatchRuleEngine.match(
        customer: fullCustomer,
        listings: const [matchingListing],
      );
      final note = matches.first.honestyNote!;
      expect(note, contains('uygun olabilir'));
      expect(note.toLowerCase(), isNot(contains('kesin')));
      expect(note.toLowerCase(), isNot(contains('yüksek ihtimalle')));
    });

    test('hiç eşleşme nedeni yoksa sonuç dönmez', () {
      const unrelated = AxionListingSnapshot(
        id: 'l2',
        title: 'Alakasız',
        region: 'İzmir',
        price: 99000000,
        propertyType: 'arsa',
      );
      final matches = PortfolioMatchRuleEngine.match(
        customer: fullCustomer,
        listings: const [unrelated],
      );
      expect(matches, isEmpty);
    });
  });
}
