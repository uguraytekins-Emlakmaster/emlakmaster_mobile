import 'package:url_launcher/url_launcher.dart';

/// Gerçek GSM/PSTN araması için `tel:` ile sistem telefon uygulamasına yönlendirme.
/// Uygulama içi “canlı hat” simülasyonu değildir.
class OutboundPhoneDial {
  OutboundPhoneDial._();

  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// TR ve uluslararası için makul uzunlukta, aranabilir sayılmış numara.
  static bool isLikelyCallablePhone(String raw) {
    final d = digitsOnly(raw);
    if (d.length < 10 || d.length > 15) return false;
    // Türkiye cep: 5XXXXXXXXX, 05..., 90...
    if (d.length == 10 && d.startsWith('5')) return true;
    if (d.length == 11 && d.startsWith('05')) return true;
    if (d.length >= 12 && d.startsWith('90')) return true;
    // Sabit hat / yurtdışı: en az 10 rakam
    return d.length >= 10;
  }

  /// `tel:` URI için rakam dizisi (boşluk ve ayırıcılar atılmış).
  static String normalizeTelDigits(String raw) => digitsOnly(raw);

  /// Sistem telefon uygulamasını açar. [raw] önce [isLikelyCallablePhone] ile doğrulanmalıdır.
  static Future<bool> launchDial(String raw) async {
    if (!isLikelyCallablePhone(raw)) return false;
    final uri = Uri.parse('tel:${normalizeTelDigits(raw)}');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
