import 'package:emlakmaster_mobile/features/ai_agent/application/uncaptured_number_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_models.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_phone_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 11, 14);

  AxionCallSnapshot call({
    required String id,
    String? customerId,
    String? phone,
    bool missed = false,
    Duration ago = const Duration(hours: 1),
  }) {
    return AxionCallSnapshot(
      id: id,
      customerId: customerId,
      phoneNumber: phone,
      isMissedOrNoAnswer: missed,
      at: now.subtract(ago),
    );
  }

  group('AxionPhoneMatcher', () {
    test('farklı biçimler aynı anahtara normalize edilir', () {
      expect(AxionPhoneMatcher.normalize('+90 532 111 22 33'),
          AxionPhoneMatcher.normalize('0532 111 22 33'));
      expect(AxionPhoneMatcher.normalize('05321112233'), '5321112233');
    });

    test('kısa numaralar anlamlı sayılmaz', () {
      expect(AxionPhoneMatcher.isMeaningful('112'), isFalse);
      expect(AxionPhoneMatcher.isMeaningful('5321112233'), isTrue);
    });

    test('bilinen küme null/boş telefonları atlar', () {
      final set = AxionPhoneMatcher.buildKnownSet([null, '', '0532 111 22 33']);
      expect(set, {'5321112233'});
    });
  });

  group('UncapturedNumberEngine', () {
    test('müşteriye bağlı çağrılar elenir', () {
      final result = UncapturedNumberEngine.detect(
        calls: [call(id: 'c1', customerId: 'cust1', phone: '05321112233')],
        knownPhoneKeys: const {},
        now: now,
      );
      expect(result, isEmpty);
    });

    test('bilinen müşteri telefonu farklı biçimde de elenir', () {
      final result = UncapturedNumberEngine.detect(
        calls: [call(id: 'c1', phone: '+90 532 111 22 33')],
        knownPhoneKeys: AxionPhoneMatcher.buildKnownSet(['0532 111 22 33']),
        now: now,
      );
      expect(result, isEmpty);
    });

    test('kayıtsız numara gruplanır ve sayımlar doğru çıkar', () {
      final result = UncapturedNumberEngine.detect(
        calls: [
          call(id: 'c1', phone: '0532 111 22 33', missed: true, ago: const Duration(hours: 2)),
          call(id: 'c2', phone: '+905321112233'),
          call(id: 'c3', phone: '0212 444 55 66', missed: true, ago: const Duration(hours: 3)),
        ],
        knownPhoneKeys: const {},
        now: now,
      );
      expect(result, hasLength(2));
      final first = result.first; // en güncel üstte
      expect(first.normalizedKey, '5321112233');
      expect(first.callCount, 2);
      expect(first.missedCount, 1);
      expect(first.lastCallWasMissed, isFalse);
      expect(first.callDocIds.first, 'c2'); // en yeni doc önce
      expect(result[1].normalizedKey, '2124445566');
    });

    test('pencere dışındaki çağrılar elenir', () {
      final result = UncapturedNumberEngine.detect(
        calls: [call(id: 'c1', phone: '05321112233', ago: const Duration(days: 20))],
        knownPhoneKeys: const {},
        now: now,
      );
      expect(result, isEmpty);
    });

    test('kısa/servis numaraları elenir', () {
      final result = UncapturedNumberEngine.detect(
        calls: [call(id: 'c1', phone: '112'), call(id: 'c2', phone: '8505')],
        knownPhoneKeys: const {},
        now: now,
      );
      expect(result, isEmpty);
    });

    test('sonuç sınırı uygulanır ve sıralama en yeniden eskiye', () {
      final calls = [
        for (var i = 0; i < 15; i++)
          call(
            id: 'c$i',
            phone: '05321112${i.toString().padLeft(3, '0')}',
            ago: Duration(hours: i + 1),
          ),
      ];
      final result = UncapturedNumberEngine.detect(
        calls: calls,
        knownPhoneKeys: const {},
        now: now,
      );
      expect(result, hasLength(UncapturedNumberEngine.defaultMaxResults));
      expect(
        result.first.lastCallAt.isAfter(result.last.lastCallAt),
        isTrue,
      );
    });

    test('deterministik: aynı girdi aynı çıktı', () {
      final calls = [
        call(id: 'c1', phone: '0532 111 22 33', missed: true),
        call(id: 'c2', phone: '0212 444 55 66'),
      ];
      final a = UncapturedNumberEngine.detect(
          calls: calls, knownPhoneKeys: const {}, now: now);
      final b = UncapturedNumberEngine.detect(
          calls: calls, knownPhoneKeys: const {}, now: now);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].normalizedKey, b[i].normalizedKey);
        expect(a[i].callCount, b[i].callCount);
      }
    });
  });
}
