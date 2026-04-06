import 'package:url_launcher/url_launcher.dart';

/// Gerçek GSM/PSTN araması için `tel:` ile sistem telefon uygulamasına yönlendirme.
/// Uygulama içi “canlı hat” simülasyonu değildir.
class OutboundPhoneDial {
  OutboundPhoneDial._();

  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// Tuş takımı / yapıştırma: yalnızca ITU tuşları ve isteğe bağlı baştaki `+`.
  /// Harf veya diğer karakterler düşürülür (bozuk görünüm / validasyon hatası önlenir).
  static String sanitizeDialEntry(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final sb = StringBuffer();
    const maxLen = 22;
    for (var i = 0; i < t.length; i++) {
      if (sb.length >= maxLen) break;
      final c = t[i];
      if (c == '+' && sb.isEmpty) {
        sb.write(c);
        continue;
      }
      if (RegExp(r'[0-9*#]').hasMatch(c)) sb.write(c);
    }
    return sb.toString();
  }

  /// [sanitizeDialEntry] sonrası CTA için “en az bir aranabilir karakter var mı”.
  static bool hasDialEntryContent(String sanitized) =>
      sanitizeDialEntry(sanitized).trim().isNotEmpty;

  /// Sadece görüntü: [sanitizeDialEntry] ile uyumlu ham değerden TR-öncelikli boşluklu metin.
  /// Arama / `tel:` için [digitsOnly] veya ham sanitized kullanılmaya devam eder.
  static String formatDialDisplayTurkeyFirst(String sanitized) {
    final s = sanitizeDialEntry(sanitized);
    if (s.isEmpty) return '';

    final suffix = _trailingStarHashRun(s);
    final core = s.substring(0, s.length - suffix.length);
    final d = digitsOnly(core);
    if (d.isEmpty) {
      return s.startsWith('+') ? '+$suffix'.trimRight() : suffix;
    }

    String formatted;

    if (d.startsWith('90')) {
      formatted = _formatPlus90Display(d);
    } else if (d.startsWith('05')) {
      formatted = _format05MobileDisplay(d);
    } else if (d.startsWith('5') && d.length <= 10) {
      formatted = _formatNationalTenStarting5(d);
    } else if (d.startsWith('0') && d.length >= 2) {
      formatted = _formatGenericDigitGroups(d, const [4, 3, 3, 2]);
    } else {
      formatted = _formatGenericInternational(d);
    }

    if (suffix.isEmpty) return formatted;
    return formatted.isEmpty ? suffix : '$formatted $suffix';
  }

  static String _trailingStarHashRun(String s) {
    var i = s.length;
    while (i > 0 && (s[i - 1] == '*' || s[i - 1] == '#')) {
      i--;
    }
    return s.substring(i);
  }

  /// +90 536 826 07 13 — [d] rakamları 90 ile başlar (baştaki + ayrı değil).
  static String _formatPlus90Display(String d) {
    if (!d.startsWith('90')) return _formatGenericInternational(d);
    final rest = d.substring(2);
    if (rest.isEmpty) return '+90';
    final g = _group5xxXxxXxXx(rest);
    return '+90 $g'.trimRight();
  }

  /// 0536 826 07 13
  static String _format05MobileDisplay(String d) {
    if (!d.startsWith('05')) return _formatGenericInternational(d);
    if (d.length <= 4) return d;
    final head = d.substring(0, 4);
    final rest = d.substring(4);
    if (rest.length <= 3) return '$head $rest';
    if (rest.length <= 5) {
      return '$head ${rest.substring(0, 3)} ${rest.substring(3)}';
    }
    final g1 = rest.substring(0, 3);
    final g2 = rest.substring(3, 5);
    final g3 = rest.substring(5);
    return '$head $g1 $g2 $g3';
  }

  /// 10 haneli 5 ile başlayan cep — 0536 826 07 13 görünümü.
  static String _formatNationalTenStarting5(String d) {
    if (d.isEmpty) return d;
    final withZero = '0$d';
    return _format05MobileDisplay(withZero);
  }

  /// 5XX XXX XX XX — kısmi girişe uyumlu.
  static String _group5xxXxxXxXx(String rest) {
    if (rest.isEmpty) return '';
    if (rest.length <= 3) return rest;
    if (rest.length <= 6) {
      return '${rest.substring(0, 3)} ${rest.substring(3)}';
    }
    if (rest.length <= 8) {
      return '${rest.substring(0, 3)} ${rest.substring(3, 6)} ${rest.substring(6)}';
    }
    final take = rest.length > 10 ? 10 : rest.length;
    final r = rest.substring(0, take);
    return '${r.substring(0, 3)} ${r.substring(3, 6)} ${r.substring(6, 8)} ${r.substring(8)}';
  }

  static String _formatGenericDigitGroups(String d, List<int> pattern) {
    if (d.isEmpty) return '';
    final b = StringBuffer();
    var i = 0;
    var pi = 0;
    while (i < d.length && pi < pattern.length) {
      final take = pattern[pi].clamp(0, d.length - i);
      if (take == 0) break;
      if (b.isNotEmpty) b.write(' ');
      b.write(d.substring(i, i + take));
      i += take;
      pi++;
    }
    if (i < d.length) {
      if (b.isNotEmpty) b.write(' ');
      b.write(d.substring(i));
    }
    return b.toString();
  }

  static String _formatGenericInternational(String d) {
    if (d.isEmpty) return '';
    if (d.length <= 4) return d;
    final parts = <String>[];
    var i = 0;
    while (i < d.length) {
      final remaining = d.length - i;
      final take = remaining <= 4 ? remaining : 3;
      parts.add(d.substring(i, i + take));
      i += take;
    }
    return parts.join(' ');
  }

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
