import 'package:emlakmaster_mobile/features/ai_agent/application/message_template_engine.dart';
import 'package:emlakmaster_mobile/features/ai_agent/domain/axion_agent_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageTemplateEngine', () {
    test('ilk takip mesajı isimle başlar', () {
      final d = MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.firstFollowUp,
        customerName: 'Ali Veli',
      ));
      expect(d.body, startsWith('Ali Veli merhaba'));
      expect(d.sourceType, AxionAgentSourceType.template);
    });

    test('sessiz müşteri mesajı bölgeyi içerir', () {
      final d = MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.silentCustomerReactivation,
        customerName: 'Ayşe',
        region: 'Kadıköy',
      ));
      expect(d.body, contains('Kadıköy bölgesindeki'));
      expect(d.body, contains('tekrar değerlendirebilirim'));
    });

    test('cevapsız arama mesajı doğru kalıptadır', () {
      final d = MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.noAnswerCallback,
        customerName: 'Mehmet',
      ));
      expect(d.body, contains('sizi aradım fakat ulaşamadım'));
    });

    test('eksik bütçe mesajı netleştirme ister', () {
      final d = MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.missingBudgetClarification,
        customerName: 'Zeynep',
      ));
      expect(d.body, contains('bütçe aralığını netleştirebilir miyiz'));
    });

    test('isim yoksa "Merhaba" ile başlar ve dürüstlük notu ekler', () {
      final d = MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.portfolioShare,
      ));
      expect(d.body, startsWith('Merhaba'));
      expect(d.honestyNote, isNotNull);
      expect(d.honestyNote, contains('müşteri adı'));
    });

    test('requiresReview her zaman true', () {
      for (final category in AxionMessageTemplateCategory.values) {
        final d = MessageTemplateEngine.generate(AxionMessageTemplateInput(
          category: category,
          customerName: 'Test',
        ));
        expect(d.requiresReview, isTrue, reason: 'category=$category');
      }
    });

    test('dış kanal (WhatsApp/SMS) uyarı taşır, internal taşımaz', () {
      final wa = MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.firstFollowUp,
        channel: AxionMessageChannel.sms,
      ));
      expect(wa.externalChannelWarning, isNotNull);

      final internal =
          MessageTemplateEngine.generate(const AxionMessageTemplateInput(
        category: AxionMessageTemplateCategory.firstFollowUp,
        channel: AxionMessageChannel.internal,
      ));
      expect(internal.externalChannelWarning, isNull);
    });

    test('abartılı vaat içermez', () {
      for (final category in AxionMessageTemplateCategory.values) {
        final d = MessageTemplateEngine.generate(AxionMessageTemplateInput(
          category: category,
          customerName: 'Test',
          region: 'Beşiktaş',
          listingTitle: 'Deniz manzaralı 3+1',
        ));
        expect(d.body.toLowerCase(), isNot(contains('kesin fırsat')));
        expect(d.body.toLowerCase(), isNot(contains('kaçırılmayacak')));
      }
    });
  });
}
