import 'package:emlakmaster_mobile/core/services/tcmb_public_rates.dart';
import 'package:flutter_test/flutter_test.dart';

/// TCMB `today.xml` yapısına yakın minimal örnek (ağ çağrısı yok).
String _sampleTodayXml({
  String usdSell = '34.5678',
  String eurSell = '37.1234',
  String? xauSell,
}) {
  final xauBlock = xauSell != null
      ? '''
  <Currency CrossOrder="998" Kod="XAU" CurrencyCode="XAU">
    <Unit>1</Unit>
    <Isim>ALTIN (ONS)</Isim>
    <ForexBuying>$xauSell</ForexBuying>
    <ForexSelling>$xauSell</ForexSelling>
  </Currency>'''
      : '';
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<Tarih_Date Tarih="19.03.2025" Date="03/19/2025" Bulten_No="2025/99">
  <Currency CrossOrder="0" Kod="USD" CurrencyCode="USD">
    <Unit>1</Unit>
    <Isim>ABD DOLARI</Isim>
    <ForexBuying>34.0000</ForexBuying>
    <ForexSelling>$usdSell</ForexSelling>
  </Currency>
  <Currency CrossOrder="1" Kod="EUR" CurrencyCode="EUR">
    <Unit>1</Unit>
    <Isim>EURO</Isim>
    <ForexBuying>37.0000</ForexBuying>
    <ForexSelling>$eurSell</ForexSelling>
  </Currency>
$xauBlock
</Tarih_Date>
''';
}

void main() {
  group('TcmbPublicRates.parseTodayXml', () {
    test('USD ve EUR kurlarını okur', () {
      final r = TcmbPublicRates.parseTodayXml(_sampleTodayXml());
      expect(r, isNotNull);
      expect(r!.usdTry, closeTo(34.5678, 1e-6));
      expect(r.eurTry, closeTo(37.1234, 1e-6));
      expect(r.gramGoldTry, isNull);
    });

    test('XAU varsa gram altına çevirir (ons / 31.1035)', () {
      const onsTry = 3103.5;
      final r = TcmbPublicRates.parseTodayXml(
        _sampleTodayXml(xauSell: onsTry.toString()),
      );
      expect(r, isNotNull);
      expect(r!.gramGoldTry, closeTo(onsTry / 31.1035, 1e-6));
    });

    test('virgüllü ondalık sayıları parse eder', () {
      final r = TcmbPublicRates.parseTodayXml(
        _sampleTodayXml(usdSell: '34,5678', eurSell: '37,12'),
      );
      expect(r, isNotNull);
      expect(r!.usdTry, closeTo(34.5678, 1e-6));
      expect(r.eurTry, closeTo(37.12, 1e-6));
    });

    test('USD veya EUR eksikse null döner', () {
      const bad = '''
<?xml version="1.0" encoding="UTF-8"?>
<Tarih_Date>
  <Currency Kod="USD" CurrencyCode="USD">
    <ForexSelling>34.0</ForexSelling>
  </Currency>
</Tarih_Date>
''';
      expect(TcmbPublicRates.parseTodayXml(bad), isNull);
    });

    test('geçersiz XML null döner', () {
      expect(TcmbPublicRates.parseTodayXml('not xml'), isNull);
    });
  });
}
