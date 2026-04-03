/// Çağrı özeti için ek katman — kural tabanlı skorları değiştirmez; yalnızca okuma desteği.
/// Sezgisel zenginleştirme **v3**: mod + transkript kalitesi; transkript yumuşak ipuçları (CRM değil).
library post_call_ai_enrichment;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment_input.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';

enum PostCallAiEnrichmentSource {
  heuristic,
  cloud,
}

class PostCallAiEnrichment {
  const PostCallAiEnrichment({
    required this.aiSummaryShortTr,
    required this.aiCustomerMoodTr,
    required this.aiObjectionTypeTr,
    required this.aiFollowUpStyleTr,
    required this.aiBrokerNoteTr,
    required this.source,
    this.enrichmentInputMode,
  });

  final String aiSummaryShortTr;
  final String aiCustomerMoodTr;
  final String aiObjectionTypeTr;
  final String aiFollowUpStyleTr;
  final String aiBrokerNoteTr;
  final PostCallAiEnrichmentSource source;
  /// Zenginleştirme girdisi modu (debug / analitik; isteğe bağlı).
  final PostCallAiEnrichmentInputMode? enrichmentInputMode;

  Map<String, dynamic> toFirestoreMap() => {
        'aiSummaryShortTr': aiSummaryShortTr,
        'aiCustomerMoodTr': aiCustomerMoodTr,
        'aiObjectionTypeTr': aiObjectionTypeTr,
        'aiFollowUpStyleTr': aiFollowUpStyleTr,
        'aiBrokerNoteTr': aiBrokerNoteTr,
        'source': source == PostCallAiEnrichmentSource.cloud ? 'cloud' : 'heuristic',
        if (enrichmentInputMode != null) 'enrichmentInputMode': enrichmentInputMode!.storageId,
      };

  static PostCallAiEnrichment? tryFromFirestoreMap(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final short = m['aiSummaryShortTr'] as String? ?? '';
    if (short.isEmpty) return null;
    return PostCallAiEnrichment(
      aiSummaryShortTr: short,
      aiCustomerMoodTr: m['aiCustomerMoodTr'] as String? ?? '',
      aiObjectionTypeTr: m['aiObjectionTypeTr'] as String? ?? '',
      aiFollowUpStyleTr: m['aiFollowUpStyleTr'] as String? ?? '',
      aiBrokerNoteTr: m['aiBrokerNoteTr'] as String? ?? '',
      source: (m['source'] as String?) == 'cloud'
          ? PostCallAiEnrichmentSource.cloud
          : PostCallAiEnrichmentSource.heuristic,
      enrichmentInputMode:
          PostCallAiEnrichmentInputMode.tryParse(m['enrichmentInputMode'] as String?),
    );
  }
}

/// Kayıtlı zenginleştirme — broker / dashboard satırları (ek hesaplama yok).
/// Önce [PostCallAiEnrichment.aiBrokerNoteTr], boşsa [PostCallAiEnrichment.aiSummaryShortTr].
String? savedAiInsightSnippetTr(PostCallAiEnrichment? ai) {
  if (ai == null) return null;
  final n = ai.aiBrokerNoteTr.trim();
  if (n.isNotEmpty) return n;
  final s = ai.aiSummaryShortTr.trim();
  return s.isNotEmpty ? s : null;
}

const int _kMaxChars = 118;

/// Cloud / debug payload için kısa etiket (`weak` / `good`).
String? transcriptQualityLabelForPayload(String? transcriptRaw) {
  switch (_analyzeTranscriptQuality(transcriptRaw ?? '')) {
    case _TranscriptQualityTier.none:
      return null;
    case _TranscriptQualityTier.weak:
      return 'weak';
    case _TranscriptQualityTier.good:
      return 'good';
  }
}

enum _TranscriptQualityTier {
  none,
  weak,
  good,
}

_TranscriptQualityTier _analyzeTranscriptQuality(String transcript) {
  final t = transcript.trim();
  if (t.isEmpty) return _TranscriptQualityTier.none;
  final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  if (t.length < 22 || words < 6) return _TranscriptQualityTier.weak;
  return _TranscriptQualityTier.good;
}

/// Transkriptten yalnızca okuma amaçlı yumuşak ipuçları (deterministik CRM motoru değil).
class _TranscriptSoft {
  const _TranscriptSoft({
    required this.priceHeavy,
    required this.urgencyHeavy,
    required this.appointmentHeavy,
    required this.questionHeavy,
    required this.hesitationHeavy,
  });

  final bool priceHeavy;
  final bool urgencyHeavy;
  final bool appointmentHeavy;
  final bool questionHeavy;
  final bool hesitationHeavy;
}

_TranscriptSoft _analyzeTranscriptSoft(String transcript) {
  final l = transcript.toLowerCase();
  final qCount = '?'.allMatches(transcript).length;
  final wordCount = transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  final questionHeavy = qCount >= 2 || (wordCount > 0 && qCount / wordCount >= 0.08);

  return _TranscriptSoft(
    priceHeavy: _containsAnyTr(
      l,
      const ['fiyat', 'pahalı', 'pahalıydı', 'bütçe', 'uçuk', 'pazarlık', 'tl ', 'milyon', 'kira', 'masraf'],
    ),
    urgencyHeavy: _containsAnyTr(
      l,
      const ['acil', 'hemen', 'bugün', 'yarın', 'bu hafta', 'bekleyemem', 'zamanım yok'],
    ),
    appointmentHeavy: _containsAnyTr(
      l,
      const ['randevu', 'görüşme', 'gösterim', 'saat ', 'saatte', 'buluşalım', 'takvim'],
    ),
    questionHeavy: questionHeavy,
    hesitationHeavy: _containsAnyTr(
      l,
      const ['belki', 'emin değilim', 'düşünüyorum', 'kararsız', 'hayır diyemem', 'şöyle böyle'],
    ),
  );
}

bool _containsAnyTr(String lower, List<String> needles) {
  for (final n in needles) {
    if (n.isEmpty) continue;
    if (lower.contains(n)) return true;
  }
  return false;
}

String _capAtWord(String s, [int max = _kMaxChars]) {
  final t = s.trim();
  if (t.length <= max) return t;
  var cut = t.substring(0, max);
  final sp = cut.lastIndexOf(' ');
  if (sp > 32) cut = cut.substring(0, sp);
  return '$cut…';
}

/// Özet + CRM sinyalleri + (opsiyonel) duygu + (opsiyonel) sıcaklık — ağ yokken güvenli Türkçe metinler.
/// [input] moduna göre özet/transkript ağırlığı değişir; transkript yalnızca sezgisel katmanda kullanılır.
/// Deterministik CRM kaydı **ezmez**.
PostCallAiEnrichment computeHeuristicPostCallAiEnrichment({
  required PostCallAiEnrichmentInput input,
  PostCallCrmSignals? signals,
  String? sentimentLabelTr,
  CustomerHeatLevel? heatLevel,
}) {
  final s = signals;
  final mode = input.mode;
  final sum = input.summaryForCrm.trim();
  final tr = input.transcriptRaw?.trim() ?? '';
  final tq = _analyzeTranscriptQuality(tr);
  final soft = _analyzeTranscriptSoft(tr);

  final summary = _v3SummaryLine(mode, sum, tr, tq, soft, s);
  final mood = _v3MoodLine(sentimentLabelTr, s, heatLevel, mode, tq, soft);
  final objection = _v3ObjectionLine(s, mode, tq, soft);
  final followUp = _v3FollowUpLine(s, mode, tq, soft);
  final broker = _v3BrokerLine(s, mode, tq, soft);

  return PostCallAiEnrichment(
    aiSummaryShortTr: _capAtWord(summary),
    aiCustomerMoodTr: _capAtWord(mood),
    aiObjectionTypeTr: _capAtWord(objection),
    aiFollowUpStyleTr: _capAtWord(followUp),
    aiBrokerNoteTr: _capAtWord(broker),
    source: PostCallAiEnrichmentSource.heuristic,
    enrichmentInputMode: mode,
  );
}

String _v3SummaryLine(
  PostCallAiEnrichmentInputMode mode,
  String sum,
  String tr,
  _TranscriptQualityTier tq,
  _TranscriptSoft soft,
  PostCallCrmSignals? s,
) {
  switch (mode) {
    case PostCallAiEnrichmentInputMode.summaryOnly:
      return _v2SummaryLine(sum, s);
    case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
      final base = _v2SummaryLine(sum, s);
      if (tq == _TranscriptQualityTier.none) return base;
      if (tq == _TranscriptQualityTier.weak) {
        return _mergeWithDot(
          base,
          'Transkript çok kısa; tam içgörü için daha fazla metin veya özet ekleyin.',
        );
      }
      return _mergeWithDot(base, _transcriptInsightSuffix(soft));
    case PostCallAiEnrichmentInputMode.transcriptOnly:
      if (tq == _TranscriptQualityTier.none) {
        return 'Özet yok; transkript de boş — kesin öneri için özet veya transkript ekleyin.';
      }
      if (tq == _TranscriptQualityTier.weak) {
        return 'Özet yok; ham transkript kısa veya belirsiz — kesin öneri için kısa özet yazın.';
      }
      final ex = _capAtWord(tr, 80);
      return _capAtWord(
        'Konuşma kaynağı (özet yok): $ex — CRM için kısa özet yazın.',
      );
  }
}

String _transcriptInsightSuffix(_TranscriptSoft soft) {
  if (soft.questionHeavy) {
    return 'Konuşmada soru yoğunluğu yüksek; dinleyerek netleştirin.';
  }
  if (soft.priceHeavy) {
    return 'Transkriptte fiyat/bütçe vurgusu belirgin.';
  }
  if (soft.appointmentHeavy) {
    return 'Transkriptte randevu/tarih geçişi dikkat çekiyor.';
  }
  if (soft.hesitationHeavy) {
    return 'Konuşmada tereddüt ifadeleri var; güven ve somut örnek sunun.';
  }
  if (soft.urgencyHeavy) {
    return 'Transkriptte zaman baskısı ifadeleri geçiyor.';
  }
  return 'Transkript konuşma tonunu destekliyor.';
}

String _mergeWithDot(String base, String suffix) {
  final b = base.trim();
  final s = suffix.trim();
  if (s.isEmpty) return b;
  if (b.isEmpty) return s;
  return _capAtWord('$b · $s');
}

String _v3MoodLine(
  String? sentimentLabelTr,
  PostCallCrmSignals? s,
  CustomerHeatLevel? heat,
  PostCallAiEnrichmentInputMode mode,
  _TranscriptQualityTier tq,
  _TranscriptSoft soft,
) {
  if (sentimentLabelTr != null && sentimentLabelTr.trim().isNotEmpty) {
    return sentimentLabelTr.trim();
  }
  switch (mode) {
    case PostCallAiEnrichmentInputMode.transcriptOnly:
      if (tq != _TranscriptQualityTier.good) {
        return 'Ton belirsiz; kısa transkriptten kesin çıkarım yapmayın.';
      }
      return _moodFromTranscriptSoft(soft);
    case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
      final base = _v2MoodLine(null, s, heat);
      if (tq != _TranscriptQualityTier.good) return base;
      if (soft.questionHeavy) {
        return _mergeWithDot(base, 'Soru yoğunluğu yüksek; sırayla yanıtlayın.');
      }
      if (soft.hesitationHeavy) {
        return _mergeWithDot(base, 'Tereddüt ifadeleri geçti; empati ve seçenek sunun.');
      }
      return base;
    case PostCallAiEnrichmentInputMode.summaryOnly:
      return _v2MoodLine(null, s, heat);
  }
}

String _moodFromTranscriptSoft(_TranscriptSoft soft) {
  if (soft.hesitationHeavy) {
    return 'Tereddüt ve koşullu ifadeler; empati ve net seçenek sunun.';
  }
  if (soft.priceHeavy) {
    return 'Fiyat/bütçe teması baskın; değer ve senaryo ile yanıtlayın.';
  }
  if (soft.questionHeavy) {
    return 'Çok soru; önce ihtiyacı özetleyip sonra tek tek yanıtlayın.';
  }
  if (soft.urgencyHeavy) {
    return 'Zaman baskısı ifadeleri var; takvim ve tek seçenek sunun.';
  }
  return 'Konuşma tonunu özetleyin; transkript tam kayıt değildir.';
}

String _v3ObjectionLine(
  PostCallCrmSignals? s,
  PostCallAiEnrichmentInputMode mode,
  _TranscriptQualityTier tq,
  _TranscriptSoft soft,
) {
  switch (mode) {
    case PostCallAiEnrichmentInputMode.transcriptOnly:
      if (tq != _TranscriptQualityTier.good) {
        return 'Kesin itiraz sınıflaması yok; deterministik CRM için özet kullanın.';
      }
      if (soft.priceHeavy) {
        return 'Fiyat/bütçe teması transkriptte öne çıkıyor; rakam ve alternatif hazırlayın.';
      }
      if (soft.appointmentHeavy) {
        return 'Randevu/tarih teması belirgin; teyit ve net saat şart.';
      }
      if (soft.urgencyHeavy) {
        return 'Zaman baskısı ifadeleri var; gecikme güveni zedeler.';
      }
      return 'Belirgin itiraz etiketi yok; metni dinleyerek önceliklendirin.';
    case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
      final base = _v2ObjectionLine(s);
      if (tq != _TranscriptQualityTier.good) return base;
      if (soft.priceHeavy && s != null && !s.priceObjection) {
        return _mergeWithDot(
          base,
          'Transkriptte fiyat/bütçe dili belirgin; özetle tutarlılığı kontrol edin.',
        );
      }
      if (soft.appointmentHeavy && s != null && !s.appointmentMentioned) {
        return _mergeWithDot(
          base,
          'Transkriptte randevu/tarih geçişi var; özetle çelişmiyorsa netleştirin.',
        );
      }
      if (tq == _TranscriptQualityTier.good && soft.priceHeavy && s == null) {
        return _mergeWithDot(
          base,
          'Transkriptte fiyat/bütçe dili belirgin; özetle doğrulayın.',
        );
      }
      return base;
    case PostCallAiEnrichmentInputMode.summaryOnly:
      return _v2ObjectionLine(s);
  }
}

String _v3FollowUpLine(
  PostCallCrmSignals? s,
  PostCallAiEnrichmentInputMode mode,
  _TranscriptQualityTier tq,
  _TranscriptSoft soft,
) {
  switch (mode) {
    case PostCallAiEnrichmentInputMode.transcriptOnly:
      if (tq != _TranscriptQualityTier.good) {
        return 'Takip önerisi yumuşak; transkript yetersiz veya özet ekleyin.';
      }
      if (soft.urgencyHeavy) {
        return 'Bugün içinde kısa teyit; tek net seçenek ve saat önerin.';
      }
      if (soft.appointmentHeavy) {
        return 'Randevu/gösterim için iki slot önerin; müşteri seçsin.';
      }
      return 'Kısa bir hatırlatma ve somut net soru ile ilerleyin.';
    case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
      final base = _v2FollowUpLine(s);
      if (tq != _TranscriptQualityTier.good) return base;
      if (soft.questionHeavy) {
        return _mergeWithDot(base, 'Önce yazılı özet veya mesajla soruları kapatabilirsiniz.');
      }
      return base;
    case PostCallAiEnrichmentInputMode.summaryOnly:
      return _v2FollowUpLine(s);
  }
}

String _v3BrokerLine(
  PostCallCrmSignals? s,
  PostCallAiEnrichmentInputMode mode,
  _TranscriptQualityTier tq,
  _TranscriptSoft soft,
) {
  switch (mode) {
    case PostCallAiEnrichmentInputMode.transcriptOnly:
      if (tq != _TranscriptQualityTier.good) {
        return 'Kesin kapanış tekniği önermeyin; özet veya net transkript sonrası tekrar deneyin.';
      }
      if (soft.priceHeavy) {
        return 'Fiyat konusunda iki senaryo (değer + ödeme) hazırlayıp tek seçenek sunun.';
      }
      if (soft.appointmentHeavy) {
        return 'Randevu için iki saat önerin; teyit SMS’i atın.';
      }
      return 'Transkriptten somut bir sonraki adım çıkarın; özetleyerek netleştirin.';
    case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
      final base = _v2BrokerLine(s);
      if (tq != _TranscriptQualityTier.good) return base;
      return _mergeWithDot(
        base,
        'Transkriptte geçen ihtiyaca göre somut bir örnek hazırlayın.',
      );
    case PostCallAiEnrichmentInputMode.summaryOnly:
      return _v2BrokerLine(s);
  }
}

/// Görüşmenin özü — satış dilinde, metinden veya sinyalden türetilmiş tek satır.
String _v2SummaryLine(String t, PostCallCrmSignals? s) {
  if (t.isEmpty) {
    return 'Özeti birkaç cümleyle netleştirin; ihtiyaç ve bütçe görünür olsun.';
  }
  final excerpt = _capAtWord(t, 100);
  final lead = switch (s?.interestLevel) {
    PostCallCrmSignals.interestHigh when s?.followUpUrgency == PostCallCrmSignals.urgencyHigh =>
      'Öncelikli talep: ',
    PostCallCrmSignals.interestHigh => 'Güçlü ilgi: ',
    PostCallCrmSignals.interestLow => 'Ilık ilgi: ',
    _ => '',
  };
  if (lead.isEmpty) return excerpt;
  final combined = '$lead$excerpt';
  return combined.length <= _kMaxChars ? combined : excerpt;
}

/// Müşteri tonu — duygu + sıcaklık + ilgi; özet ve itiraz cümlelerini kopyalamaz.
String _v2MoodLine(
  String? sentimentLabelTr,
  PostCallCrmSignals? s,
  CustomerHeatLevel? heat,
) {
  if (sentimentLabelTr != null && sentimentLabelTr.trim().isNotEmpty) {
    return sentimentLabelTr.trim();
  }
  final heatHint = switch (heat) {
    CustomerHeatLevel.hot => 'Portföy sıcak; güven ve somut seçenekle ilerleyin.',
    CustomerHeatLevel.warm => 'İlgi var; net değer önerisi ile sıcaklığı artırın.',
    CustomerHeatLevel.cool => 'Temas sığ; ihtiyaç ve zamanlamayı sorgulayın.',
    CustomerHeatLevel.cold => 'Erken aşama; baskı yapmadan bilgi paylaşın.',
    null => '',
  };
  if (heatHint.isNotEmpty && s == null) return heatHint;

  if (s != null) {
    final u = s.followUpUrgency;
    final i = s.interestLevel;
    if (u == PostCallCrmSignals.urgencyHigh && i == PostCallCrmSignals.interestHigh) {
      return 'Karar anına yakın bir enerji; sakin ve seçenek odaklı kalın.';
    }
    if (u == PostCallCrmSignals.urgencyHigh) {
      return 'Zaman baskısı var; net takvim ve tek seçenek sunmak işe yarar.';
    }
    if (i == PostCallCrmSignals.interestHigh) {
      return 'Alıcı taraf istekli; güven ve somut adım bekliyor.';
    }
    if (i == PostCallCrmSignals.interestLow) {
      return 'Temkinli yaklaşım; değer anlatımı ve nazik tempo uygun.';
    }
  }
  if (heatHint.isNotEmpty) return heatHint;
  return 'Dengeli bir görüşme tonu; dinleyerek netleştirin.';
}

/// İtiraz / sürtünme türü — fiyat, randevu, zaman veya “belirsiz”.
String _v2ObjectionLine(PostCallCrmSignals? s) {
  if (s == null) {
    return 'Metinden belirgin itiraz tipi çıkmadı; ihtiyacı sorarak netleştirin.';
  }
  if (s.priceObjection && s.interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Fiyat-bütçe hassasiyeti yüksek ilgiyle birlikte; değer ve senaryo şart.';
  }
  if (s.priceObjection) {
    return 'Bütçe veya fiyat öne çıktı; rakam ve alternatif planla ilerleyin.';
  }
  if (s.appointmentMentioned && s.followUpUrgency == PostCallCrmSignals.urgencyHigh) {
    return 'Randevu zamanı kritik; net saat ve teyit bekleniyor.';
  }
  if (s.appointmentMentioned) {
    return 'Randevu konuşuldu; takvim ve mekan netleşmeden risk var.';
  }
  if (s.followUpUrgency == PostCallCrmSignals.urgencyHigh) {
    return 'Acil takip beklentisi; gecikme güveni zedeler.';
  }
  return 'Belirgin bir itiraz yok; dinleyerek önceliği netleştirin.';
}

/// Ne zaman, hangi kanal — tekrar yok; broker satırından farklı odak.
String _v2FollowUpLine(PostCallCrmSignals? s) {
  if (s == null) {
    return 'Hafta içi kısa mesaj veya arama ile nazik hatırlatma yeterli.';
  }
  final u = s.followUpUrgency;
  if (u == PostCallCrmSignals.urgencyHigh && s.appointmentMentioned) {
    return 'Bugün WhatsApp veya kısa arama ile randevu saatini kilitleyin.';
  }
  if (u == PostCallCrmSignals.urgencyHigh) {
    return 'Bugün içinde telefon veya mesaj; tek net seçenek sunun.';
  }
  if (u == PostCallCrmSignals.urgencyMedium) {
    return '2–3 gün içinde kontrol; değer ekleyen kısa bir mesaj yeterli.';
  }
  if (s.interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Bu hafta bir kez temas; portföyden somut örnek paylaşın.';
  }
  return 'Seyrek ama düzenli hatırlatma; gerektiğinde arayın.';
}

/// Satış tekniği / kapanış ipucu — `nextActionHint` ile aynı cümleyi kopyalamaz.
String _v2BrokerLine(PostCallCrmSignals? s) {
  if (s == null) {
    return 'Sonraki adımı tarih veya bütçe ile tek cümlede netleştirmeyi deneyin.';
  }
  if (s.priceObjection) {
    return 'Önce değer ölçütünü sorun, sonra rakam; iki senaryo hazırlayın.';
  }
  if (s.appointmentMentioned) {
    return 'Takvimde iki slot önerin; müşteri seçsin, siz teyit SMS’i atın.';
  }
  if (s.followUpUrgency == PostCallCrmSignals.urgencyHigh) {
    return 'Kapanış için “bugün hangi saatte?” sorusunu açık bırakmayın.';
  }
  if (s.interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Tek uygun ilanı öne çıkarıp nedenini bir cümlede anlatın.';
  }
  if (s.nextActionHint.trim().isNotEmpty) {
    return 'Önerilen aksiyona ek olarak tek cümlede teyit isteyin.';
  }
  return 'Görüşmeyi somut bir sonraki adım (tarih veya görüntüleme) ile kapatın.';
}

/// Sihirbazdaki [CallSentiment] için kısa etiket (post_call_wizard ile uyumlu). v2 tonu.
String sentimentLabelTrFromStorage(String? stored) {
  switch (stored) {
    case 'very_positive':
      return 'İstekli ve pozitif; hızlı somut adım bekliyor.';
    case 'uncertain':
      return 'Kararsızlık var; güven veren bilgi ve örnek işe yarar.';
    case 'analytical':
      return 'Detay odaklı; rakam ve karşılaştırma ile güven kazanın.';
    case 'low_interest':
      return 'Ilık ilgi; baskı yapmadan değer ve zaman kazanın.';
    case 'urgent':
      return 'Zaman baskısı belirgin; net takvim ve seçenek sunun.';
    default:
      return 'Dengeli bir görüşme tonu; dinleyerek netleştirin.';
  }
}
