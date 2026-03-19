import 'package:emlakmaster_mobile/features/voice_crm/domain/usecases/extract_voice_crm_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExtractVoiceCrmIntent extractor;

  setUp(() {
    extractor = ExtractVoiceCrmIntent();
  });

  group('ExtractVoiceCrmIntent', () {
    test('empty transcript returns empty intent', () {
      final intent = extractor.call('');
      expect(intent.rawSummary, isNull);
      expect(intent.addOffer, isNull);
      expect(intent.setReminderAt, isNull);
    });

    test('extracts offer from "7 milyon teklif"', () {
      final intent = extractor.call('Ahmet ile görüştüm, 7 milyon teklif verdim.');
      expect(intent.addOffer, isNotNull);
      expect(intent.addOffer!.amount, closeTo(7e6, 1));
    });

    test('extracts reminder from "yarın takip"', () {
      final intent = extractor.call('Yarın tekrar arayacağım.');
      expect(intent.setReminderAt, isNotNull);
      expect(intent.setReminderAt!.day, DateTime.now().add(const Duration(days: 1)).day);
    });

    test('extracts updateLead when "görüşme" in transcript', () {
      final intent = extractor.call('Müşteri ile görüşme yaptım, 5 milyon TL dedi.');
      expect(intent.updateLead, isNotNull);
      expect(intent.rawSummary, isNotNull);
    });
  });
}
