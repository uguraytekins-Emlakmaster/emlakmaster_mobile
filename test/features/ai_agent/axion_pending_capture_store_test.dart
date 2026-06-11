import 'package:emlakmaster_mobile/features/ai_agent/data/axion_pending_capture_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AxionPendingCaptureStore — bekleyen kayıtlar', () {
    test('enqueueSave + takeSaves: kayıt döner ve kuyruk temizlenir', () async {
      final store = AxionPendingCaptureStore.instance;
      await store.enqueueSave(name: 'Ahmet Yılmaz', phone: '0532 111 22 33');

      final saves = await store.takeSaves();
      expect(saves, hasLength(1));
      expect(saves.first.name, 'Ahmet Yılmaz');
      expect(saves.first.phone, '0532 111 22 33');

      // İkinci çağrı boş dönmeli (kuyruk tüketildi).
      expect(await store.takeSaves(), isEmpty);
    });

    test('aynı telefon tekrar eklenirse eski kayıt değiştirilir', () async {
      final store = AxionPendingCaptureStore.instance;
      await store.enqueueSave(name: 'Eski İsim', phone: '05321112233');
      await store.enqueueSave(name: 'Yeni İsim', phone: '05321112233');

      final saves = await store.takeSaves();
      expect(saves, hasLength(1));
      expect(saves.first.name, 'Yeni İsim');
    });

    test('kuyruk üst sınırı aşılmaz (en eskiler düşer)', () async {
      final store = AxionPendingCaptureStore.instance;
      for (var i = 0; i < 30; i++) {
        await store.enqueueSave(name: 'Kişi $i', phone: '05300000$i');
      }
      final saves = await store.takeSaves();
      expect(saves.length, lessThanOrEqualTo(25));
      // En yeni kayıt korunur.
      expect(saves.last.name, 'Kişi 29');
    });
  });

  group('AxionPendingCaptureStore — bekleyen bağlamalar', () {
    test('enqueueLink + takeLinks: harita döner ve temizlenir', () async {
      final store = AxionPendingCaptureStore.instance;
      await store.enqueueLink(normalizedKey: '5321112233', customerId: 'c1');
      await store.enqueueLink(normalizedKey: '5444445566', customerId: 'c2');

      final links = await store.takeLinks();
      expect(links, {'5321112233': 'c1', '5444445566': 'c2'});
      expect(await store.takeLinks(), isEmpty);
    });

    test('aynı anahtar için son customerId kazanır', () async {
      final store = AxionPendingCaptureStore.instance;
      await store.enqueueLink(normalizedKey: '5321112233', customerId: 'c1');
      await store.enqueueLink(normalizedKey: '5321112233', customerId: 'c2');

      final links = await store.takeLinks();
      expect(links, {'5321112233': 'c2'});
    });
  });
}
