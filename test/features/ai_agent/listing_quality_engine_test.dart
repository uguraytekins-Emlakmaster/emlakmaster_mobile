import 'package:emlakmaster_mobile/features/ai_agent/application/listing_quality_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 11);

  group('ListingQualityEngine', () {
    test('eksik fiyat tespit edilir', () {
      final suggestions = ListingQualityEngine.analyze(
        listings: const [
          AxionListingSnapshot(
            id: 'l1',
            title: 'Fiyatsız ilan',
            hasLocation: true,
            hasCoverImage: true,
            propertyType: 'daire',
            roomCount: 3,
            description: 'Geniş ve ferah bir daire, merkezi konum.',
            hasOwnerContact: true,
            status: 'active',
          ),
        ],
        now: now,
      );
      expect(suggestions, hasLength(1));
      expect(suggestions.first.title, 'Portföy fiyat bilgisini tamamla');
      expect(suggestions.first.missingData, contains('fiyat'));
    });

    test('eksik kapak görseli tespit edilir', () {
      final suggestions = ListingQualityEngine.analyze(
        listings: const [
          AxionListingSnapshot(
            id: 'l2',
            title: 'Görselsiz',
            price: 1000000,
            hasLocation: true,
            propertyType: 'daire',
            roomCount: 2,
            description: 'Açıklama yeterince uzun bir metin içeriyor.',
            hasOwnerContact: true,
            status: 'active',
          ),
        ],
        now: now,
      );
      expect(suggestions.first.title, 'Kapak görseli eksik');
      expect(suggestions.first.missingData, contains('kapak görseli'));
    });

    test('eksik konum tespit edilir', () {
      final suggestions = ListingQualityEngine.analyze(
        listings: const [
          AxionListingSnapshot(
            id: 'l3',
            title: 'Konumsuz',
            price: 1000000,
            hasCoverImage: true,
            propertyType: 'daire',
            roomCount: 2,
            description: 'Açıklama yeterince uzun bir metin içeriyor.',
            hasOwnerContact: true,
            status: 'active',
          ),
        ],
        now: now,
      );
      expect(suggestions.first.title, 'Konum bilgisi eksik');
    });

    test('zayıf açıklama tespit edilir', () {
      final suggestions = ListingQualityEngine.analyze(
        listings: const [
          AxionListingSnapshot(
            id: 'l4',
            title: 'Kısa açıklama',
            price: 1000000,
            hasLocation: true,
            hasCoverImage: true,
            propertyType: 'daire',
            roomCount: 2,
            description: 'Kısa',
            hasOwnerContact: true,
            status: 'active',
          ),
        ],
        now: now,
      );
      expect(suggestions.first.title, 'Açıklama zayıf / eksik');
      expect(suggestions.first.missingData, contains('açıklama'));
    });

    test('tam ilanda öneri üretmez; sahte kalite skoru yoktur', () {
      final suggestions = ListingQualityEngine.analyze(
        listings: const [
          AxionListingSnapshot(
            id: 'l5',
            title: 'Eksiksiz ilan',
            price: 2000000,
            hasLocation: true,
            hasCoverImage: true,
            propertyType: 'daire',
            roomCount: 3,
            description: 'Geniş ve ferah bir daire, merkezi konumda yer alır.',
            hasOwnerContact: true,
            status: 'active',
          ),
        ],
        now: now,
      );
      expect(suggestions, isEmpty);
    });

    test('öneri aksiyon tipi completeListingInfo ve onay gerektirir', () {
      final suggestions = ListingQualityEngine.analyze(
        listings: const [AxionListingSnapshot(id: 'l6')],
        now: now,
      );
      final s = suggestions.first;
      expect(s.actionType, AxionAgentActionType.completeListingInfo);
      expect(s.recommendedAction?.requiresApproval, isTrue);
    });
  });
}
