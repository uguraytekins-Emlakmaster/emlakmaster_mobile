/// Hızlı çağrı sonucu — CRM’de `calls`/`quickOutcomeCode` ile uyumlu sabitler.
abstract final class QuickCallOutcome {
  QuickCallOutcome._();

  static const String reached = 'reached';
  static const String noAnswer = 'no_answer';
  static const String busy = 'busy';
  static const String callbackScheduled = 'callback_scheduled';
  static const String appointmentSet = 'appointment_set';
  static const String offerSent = 'offer_sent';

  static const List<QuickCallOutcomeItem> choices = [
    QuickCallOutcomeItem(reached, 'Ulaşıldı'),
    QuickCallOutcomeItem(noAnswer, 'Cevap yok'),
    QuickCallOutcomeItem(busy, 'Meşgul'),
    QuickCallOutcomeItem(callbackScheduled, 'Tekrar aranacak'),
    QuickCallOutcomeItem(appointmentSet, 'Randevu oluşturuldu'),
    QuickCallOutcomeItem(offerSent, 'Teklif verildi'),
  ];

  static String labelTr(String code) {
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
