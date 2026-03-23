import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// TCMB halka açık günlük kur XML — ücretli API yok, kaynak: [tcmb.gov.tr/kurlar/today.xml].
/// USD/TRY ve EUR/TRY doğrudan; altın yoksa null döner (üst katman yedek doldurur).
abstract final class TcmbPublicRates {
  TcmbPublicRates._();

  static const String todayXmlUrl = 'https://www.tcmb.gov.tr/kurlar/today.xml';

  /// XML parse edilemez veya kur yoksa null.
  static Future<TcmbParsedRates?> fetchToday() async {
    try {
      final resp = await http
          .get(Uri.parse(todayXmlUrl))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      return parseTodayXml(resp.body);
    } catch (e) {
      if (kDebugMode) debugPrint('TcmbPublicRates.fetchToday: $e');
      return null;
    }
  }

  /// Test ve offline doğrulama için.
  static TcmbParsedRates? parseTodayXml(String body) {
    try {
      final doc = XmlDocument.parse(body);
      double? usdTry;
      double? eurTry;
      double? gramGoldTry;

      for (final el in doc.findAllElements('Currency')) {
        final kod = el.getAttribute('Kod') ?? el.getAttribute('CurrencyCode');
        if (kod == null) continue;
        final sell = _firstText(el, 'ForexSelling') ?? _firstText(el, 'BanknoteSelling');
        final v = _parseTcmbNumber(sell);
        if (v == null || v <= 0) continue;

        switch (kod.toUpperCase()) {
          case 'USD':
            usdTry = v;
            break;
          case 'EUR':
            eurTry = v;
            break;
          case 'XAU':
            // TCMB ons başına TRY satış; gram = ons / 31.1035
            gramGoldTry = v / 31.1035;
            break;
        }
      }

      if (usdTry == null || eurTry == null || usdTry <= 0 || eurTry <= 0) {
        return null;
      }

      return TcmbParsedRates(
        usdTry: usdTry,
        eurTry: eurTry,
        gramGoldTry: gramGoldTry,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('TcmbPublicRates.parseTodayXml: $e');
      return null;
    }
  }

  static String? _firstText(XmlElement parent, String childName) {
    final it = parent.findElements(childName);
    if (it.isEmpty) return null;
    return it.first.innerText.trim();
  }

  /// TCMB genelde noktalı ondalık; bazen virgül.
  static double? _parseTcmbNumber(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var s = raw.trim();
    if (s.contains(',') && s.contains('.')) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }
}

/// TCMB’den okunan ham değerler (EUR/TRY doğrudan; USD ile çapraz kontrol için math kullanılabilir).
class TcmbParsedRates {
  const TcmbParsedRates({
    required this.usdTry,
    required this.eurTry,
    this.gramGoldTry,
  });

  final double usdTry;
  final double eurTry;
  final double? gramGoldTry;
}
