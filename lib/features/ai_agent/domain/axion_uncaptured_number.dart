import 'package:flutter/foundation.dart' show immutable;

/// CRM'de kayıtlı olmayan, çağrı geçmişinde görülen numara.
///
/// Yalnızca gerçek çağrı verisinden türetilir; uydurma alan yok.
@immutable
class AxionUncapturedNumber {
  const AxionUncapturedNumber({
    required this.normalizedKey,
    required this.displayNumber,
    this.contactName,
    required this.callCount,
    required this.missedCount,
    required this.lastCallAt,
    required this.lastCallWasMissed,
    required this.callDocIds,
  });

  /// Eşleme anahtarı (son 10 hane).
  final String normalizedKey;

  /// Kullanıcıya gösterilecek ham numara (en son görülen biçim).
  final String displayNumber;

  /// Telefon rehberindeki kayıtlı isim (varsa) — kayıt formu bununla
  /// önceden doldurulur, uydurma isim asla üretilmez.
  final String? contactName;

  /// Pencere içindeki toplam çağrı sayısı.
  final int callCount;

  /// Cevapsız/meşgul/ulaşılamadı sayısı.
  final int missedCount;

  /// En son çağrı zamanı.
  final DateTime lastCallAt;

  /// Son çağrı cevapsız mıydı?
  final bool lastCallWasMissed;

  /// Bu numaraya ait çağrı doküman id'leri (kayıt sonrası müşteriye
  /// bağlamak için; en yeniden eskiye).
  final List<String> callDocIds;
}
