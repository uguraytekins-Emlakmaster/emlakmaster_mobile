import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';

/// Girdi parametreleri — şablonlar yalnızca gerçek CRM verisiyle doldurulur.
class AxionMessageTemplateInput {
  const AxionMessageTemplateInput({
    required this.category,
    this.channel = AxionMessageChannel.whatsapp,
    this.tone = AxionMessageTone.professional,
    this.customerName,
    this.consultantName,
    this.region,
    this.propertyType,
    this.budget,
    this.lastContactAt,
    this.listingTitle,
    this.appointmentDate,
    this.targetCustomerId = '',
  });

  final AxionMessageTemplateCategory category;
  final AxionMessageChannel channel;
  final AxionMessageTone tone;
  final String? customerName;
  final String? consultantName;
  final String? region;
  final String? propertyType;
  final String? budget;
  final DateTime? lastContactAt;
  final String? listingTitle;
  final DateTime? appointmentDate;
  final String targetCustomerId;
}

/// Ücretsiz, ağ'sız, deterministik mesaj taslağı motoru.
///
/// Kurallar:
/// - Abartılı vaat YOK ("kesin fırsat", "kaçırılmayacak" yasak)
/// - İsim yoksa "Merhaba" ile başla
/// - Tüm taslaklar requiresReview = true
/// - Dış kanal (WhatsApp/SMS) için uyarı eklenir
abstract final class MessageTemplateEngine {
  static AxionMessageDraft generate(AxionMessageTemplateInput input) {
    final greeting = _greeting(input.customerName);
    final body = _body(input, greeting);
    final missing = _missingFields(input);

    return AxionMessageDraft(
      id: 'draft-${input.category.name}-${input.targetCustomerId.isEmpty ? DateTime.now().microsecondsSinceEpoch : input.targetCustomerId}',
      channel: input.channel,
      title: _title(input.category),
      body: body,
      tone: input.tone,
      targetCustomerId: input.targetCustomerId,
      honestyNote: missing.isEmpty
          ? null
          : 'Şablon, eksik bilgi nedeniyle genel tutuldu: ${missing.join(', ')}.',
      externalChannelWarning: input.channel.isExternal
          ? AxionAgentPolicy.externalSendWarning
          : null,
    );
  }

  static String _greeting(String? name) {
    final n = name?.trim() ?? '';
    return n.isEmpty ? 'Merhaba' : '$n merhaba';
  }

  static String _title(AxionMessageTemplateCategory c) => switch (c) {
        AxionMessageTemplateCategory.firstFollowUp => 'İlk takip mesajı',
        AxionMessageTemplateCategory.silentCustomerReactivation =>
          'Sessiz müşteri mesajı',
        AxionMessageTemplateCategory.portfolioShare => 'Portföy paylaşımı',
        AxionMessageTemplateCategory.appointmentReminder =>
          'Randevu hatırlatması',
        AxionMessageTemplateCategory.missingBudgetClarification =>
          'Bütçe netleştirme',
        AxionMessageTemplateCategory.missingRegionClarification =>
          'Bölge netleştirme',
        AxionMessageTemplateCategory.thankYouAfterCall =>
          'Görüşme teşekkürü',
        AxionMessageTemplateCategory.noAnswerCallback => 'Cevapsız dönüşü',
        AxionMessageTemplateCategory.priceUpdate => 'Fiyat güncellemesi',
        AxionMessageTemplateCategory.documentRequest => 'Belge talebi',
        AxionMessageTemplateCategory.listingInfoShare => 'İlan bilgisi',
      };

  static List<String> _missingFields(AxionMessageTemplateInput i) {
    final missing = <String>[];
    switch (i.category) {
      case AxionMessageTemplateCategory.silentCustomerReactivation:
      case AxionMessageTemplateCategory.portfolioShare:
        if ((i.region ?? '').isEmpty) missing.add('bölge');
      case AxionMessageTemplateCategory.appointmentReminder:
        if (i.appointmentDate == null) missing.add('randevu tarihi');
      case AxionMessageTemplateCategory.priceUpdate:
      case AxionMessageTemplateCategory.listingInfoShare:
        if ((i.listingTitle ?? '').isEmpty) missing.add('ilan başlığı');
      default:
        break;
    }
    if ((i.customerName ?? '').isEmpty) missing.add('müşteri adı');
    return missing;
  }

  static String _body(AxionMessageTemplateInput i, String greeting) {
    final region = (i.region ?? '').trim();
    final regionPhrase =
        region.isEmpty ? 'ilgilendiğiniz bölgedeki' : '$region bölgesindeki';
    final listing = (i.listingTitle ?? '').trim();
    final consultant = (i.consultantName ?? '').trim();
    final signature = consultant.isEmpty ? '' : '\n\n$consultant';

    final core = switch (i.category) {
      AxionMessageTemplateCategory.firstFollowUp =>
        '$greeting, görüşmemizin ardından size uygun seçenekleri değerlendirmeye başladım. '
            'Müsait olduğunuzda kısa bir görüşme yapabiliriz.',
      AxionMessageTemplateCategory.silentCustomerReactivation =>
        '$greeting, daha önce görüştüğümüz $regionPhrase portföylerle ilgili '
            'size uygun seçenekleri tekrar değerlendirebilirim. '
            'Müsait olduğunuzda kısa bir görüşme yapabiliriz.',
      AxionMessageTemplateCategory.portfolioShare =>
        '$greeting, ilgilendiğiniz kriterlere uygun olabilecek birkaç portföy hazırladım. '
            'Müsait olduğunuzda paylaşabilirim.',
      AxionMessageTemplateCategory.appointmentReminder =>
        '$greeting, ${i.appointmentDate == null ? 'planladığımız randevumuzu' : '${_fmtDate(i.appointmentDate!)} tarihindeki randevumuzu'} '
            'hatırlatmak istedim. Uygunluğunuzda görüşmek üzere.',
      AxionMessageTemplateCategory.missingBudgetClarification =>
        '$greeting, size daha doğru portföyler sunabilmem için düşündüğünüz '
            'bütçe aralığını netleştirebilir miyiz?',
      AxionMessageTemplateCategory.missingRegionClarification =>
        '$greeting, size uygun seçenekleri daraltabilmem için hangi bölgelerle '
            'ilgilendiğinizi paylaşabilir misiniz?',
      AxionMessageTemplateCategory.thankYouAfterCall =>
        '$greeting, görüşmemiz için teşekkür ederim. Konuştuğumuz konular '
            'doğrultusunda size dönüş yapacağım.',
      AxionMessageTemplateCategory.noAnswerCallback =>
        '$greeting, sizi aradım fakat ulaşamadım. Müsait olduğunuzda kısa '
            'bir görüşme yapabiliriz.',
      AxionMessageTemplateCategory.priceUpdate =>
        '$greeting, ${listing.isEmpty ? 'ilgilendiğiniz portföyde' : '"$listing" portföyünde'} '
            'fiyat güncellemesi oldu. Detayları paylaşmamı isterseniz haber verin.',
      AxionMessageTemplateCategory.documentRequest =>
        '$greeting, işlemlere devam edebilmemiz için gerekli belgeleri '
            'uygun olduğunuzda iletebilir misiniz?',
      AxionMessageTemplateCategory.listingInfoShare =>
        '$greeting, ${listing.isEmpty ? 'ilgilenebileceğiniz bir portföyün' : '"$listing" portföyünün'} '
            'detaylarını paylaşmak isterim. Müsait olduğunuzda iletebilirim.',
    };

    final toned = switch (i.tone) {
      AxionMessageTone.short => _shorten(core),
      AxionMessageTone.warm => core,
      AxionMessageTone.premium => core,
      AxionMessageTone.professional => core,
    };

    return '$toned$signature';
  }

  /// Kısa ton: ilk cümleyi al.
  static String _shorten(String body) {
    final idx = body.indexOf('. ');
    if (idx == -1) return body;
    return body.substring(0, idx + 1);
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
