/// Hızlı çağrı sonucu — CRM’de `calls`/`quickOutcomeCode` ile uyumlu sabitler.
abstract final class QuickCallOutcome {
  QuickCallOutcome._();

  static const String reached = 'reached';
  static const String noAnswer = 'no_answer';
  static const String busy = 'busy';
  static const String callbackScheduled = 'callback_scheduled';
  static const String appointmentSet = 'appointment_set';
  static const String offerSent = 'offer_sent';
  static const String priceDiscussed = 'price_discussed';
  static const String sellerIntent = 'seller_intent';
  static const String buyerIntent = 'buyer_intent';
  static const String undecided = 'undecided';
  /// Otomatik minimum kayıt (CRM oturumu yok, kullanıcı henüz hızlı kayıt yapmadı).
  static const String noCaptureYet = 'no_capture';

  /// Hızlı kayıt çipi sırası — tek dokunuş odaklı.
  static const List<QuickCallOutcomeItem> fastChips = [
    QuickCallOutcomeItem(reached, 'Ulaşıldı'),
    QuickCallOutcomeItem(noAnswer, 'Ulaşılamadı'),
    QuickCallOutcomeItem(callbackScheduled, 'Tekrar Ara'),
    QuickCallOutcomeItem(appointmentSet, 'Randevu'),
    QuickCallOutcomeItem(priceDiscussed, 'Fiyat Konuşuldu'),
    QuickCallOutcomeItem(sellerIntent, 'Satıcı'),
    QuickCallOutcomeItem(buyerIntent, 'Alıcı'),
    QuickCallOutcomeItem(undecided, 'Kararsız'),
  ];

  static const List<QuickCallOutcomeItem> choices = [
    ...fastChips,
    QuickCallOutcomeItem(busy, 'Meşgul'),
    QuickCallOutcomeItem(offerSent, 'Teklif verildi'),
  ];

  static String labelTr(String code) {
    if (code == noCaptureYet) return 'Sonuç girilmedi';
    for (final c in choices) {
      if (c.code == code) return c.labelTr;
    }
    return code;
  }
}

class QuickCallOutcomeItem {
  const QuickCallOutcomeItem(this.code, this.labelTr);

  final String code;
  final String labelTr;
}
