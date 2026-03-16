import 'package:emlakmaster_mobile/features/voice_crm/domain/entities/voice_crm_intent.dart';

/// Ses metninden CRM aksiyonları çıkarır (Türkçe: "Ahmet ile Kayapınar 3+1, 7 milyon teklif, yarın takip").
class ExtractVoiceCrmIntent {
  VoiceCrmIntent call(String transcript) {
    if (transcript.trim().isEmpty) {
      return const VoiceCrmIntent();
    }
    final lower = transcript.toLowerCase().trim();
    String? updateLead;
    ({String? customerId, double? amount})? addOffer;
    DateTime? setReminderAt;

    // Teklif: "7 milyon teklif", "5.5M teklif", "8M TL"
    final offerMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:milyon|m\s*|milyon\s*tl|m\s*tl|tl)', caseSensitive: false).firstMatch(lower);
    if (offerMatch != null) {
      final numStr = offerMatch.group(1)?.replaceAll(',', '.') ?? '';
      final amount = double.tryParse(numStr);
      if (amount != null && amount > 0) {
        final millions = amount < 100 ? amount : amount / 1e6;
        addOffer = (customerId: null, amount: millions * 1e6);
      }
    }

    // Yarın / 2 gün sonra / haftaya → hatırlatma
    final now = DateTime.now();
    if (RegExp(r'yarın|yârin').hasMatch(lower)) {
      setReminderAt = DateTime(now.year, now.month, now.day + 1, 9, 0);
    } else if (RegExp(r'2\s*gün|iki\s*gün').hasMatch(lower)) {
      setReminderAt = now.add(const Duration(days: 2));
    } else if (RegExp(r'haftaya|gelecek\s*hafta').hasMatch(lower)) {
      setReminderAt = now.add(const Duration(days: 7));
    } else if (RegExp(r'1\s*gün|bir\s*gün').hasMatch(lower)) {
      setReminderAt = now.add(const Duration(days: 1));
    }

    // Lead güncelleme: ilk isim veya "müşteri" referansı metinde kalır (updateLead = özet)
    if (lower.contains('görüşme') || lower.contains('görüştüm') || lower.contains('toplantı') || lower.contains('met with')) {
      updateLead = transcript.trim();
    }

    return VoiceCrmIntent(
      updateLead: updateLead,
      addOffer: addOffer,
      setReminderAt: setReminderAt,
      rawSummary: transcript.trim().isNotEmpty ? transcript.trim() : null,
    );
  }
}
