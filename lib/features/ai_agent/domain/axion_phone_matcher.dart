/// Deterministik telefon numarası normalizasyonu ve eşleme.
///
/// Aynı numara farklı biçimlerde gelebilir: `+90 532 111 22 33`,
/// `0532 111 22 33`, `05321112233`. Eşleme son 10 haneye göre yapılır
/// (Türkiye GSM/şehir numarası uzunluğu). AI yok, kural var.
abstract final class AxionPhoneMatcher {
  /// Yalnızca rakamları bırakır; eşleme anahtarı olarak son 10 hane.
  /// 10 haneden kısaysa olduğu gibi döner (kısa/özel numaralar).
  static String normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  /// Görüntüleme için anahtar geçerli mi? (en az 7 hane — santral/servis
  /// kısa kodları önerilmez)
  static bool isMeaningful(String normalized) => normalized.length >= 7;

  /// Müşteri telefonlarından normalize küme üretir.
  static Set<String> buildKnownSet(Iterable<String?> phones) {
    final out = <String>{};
    for (final p in phones) {
      if (p == null || p.trim().isEmpty) continue;
      final n = normalize(p);
      if (n.isNotEmpty) out.add(n);
    }
    return out;
  }
}
