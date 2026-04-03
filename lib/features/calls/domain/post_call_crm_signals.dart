/// Kural tabanlı çağrı özeti → CRM sinyalleri (Türkçe metin; hata vermez).
library post_call_crm_signals;

/// Kayıtlı özet metninden türetilen, danışmana yönelik yapılandırılmış alanlar.
class PostCallCrmSignals {
  const PostCallCrmSignals({
    required this.interestLevel,
    required this.nextActionHint,
    required this.appointmentMentioned,
    required this.priceObjection,
    required this.followUpUrgency,
  });

  /// [interestHigh], [interestMedium], [interestLow], [interestUnknown]
  final String interestLevel;

  /// Kısa Türkçe yönlendirme (kurallardan tek cümle).
  final String nextActionHint;

  final bool appointmentMentioned;
  final bool priceObjection;

  /// [urgencyHigh], [urgencyMedium], [urgencyLow], [urgencyNone]
  final String followUpUrgency;

  static const String interestHigh = 'high';
  static const String interestMedium = 'medium';
  static const String interestLow = 'low';
  static const String interestUnknown = 'unknown';

  static const String urgencyHigh = 'high';
  static const String urgencyMedium = 'medium';
  static const String urgencyLow = 'low';
  static const String urgencyNone = 'none';

  /// Boş veya anlamsız metin için güvenli varsayılan.
  factory PostCallCrmSignals.fallback() => const PostCallCrmSignals(
        interestLevel: interestUnknown,
        nextActionHint: '',
        appointmentMentioned: false,
        priceObjection: false,
        followUpUrgency: urgencyNone,
      );

  /// Firestore `lastCallSummarySignals` alt alanları (timestamp ayrı eklenir).
  Map<String, dynamic> toFirestorePayload() => {
        'interestLevel': interestLevel,
        'nextActionHint': nextActionHint,
        'appointmentMentioned': appointmentMentioned,
        'priceObjection': priceObjection,
        'followUpUrgency': followUpUrgency,
      };

  /// `customers.lastCallSummarySignals` okuma; yoksa veya boşsa null.
  static PostCallCrmSignals? tryFromFirestoreMap(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    m.remove('extractedAt');
    if (m.isEmpty) return null;
    return PostCallCrmSignals(
      interestLevel: m['interestLevel'] as String? ?? interestUnknown,
      nextActionHint: (m['nextActionHint'] as String?) ?? '',
      appointmentMentioned: m['appointmentMentioned'] as bool? ?? false,
      priceObjection: m['priceObjection'] as bool? ?? false,
      followUpUrgency: m['followUpUrgency'] as String? ?? urgencyNone,
    );
  }
}

/// Broker / liste önceliği: yüksek ilgi, acil takip, fiyat itirazı veya randevu.
bool postCallSignalsIsPriority(PostCallCrmSignals s) {
  return s.interestLevel == PostCallCrmSignals.interestHigh ||
      s.followUpUrgency == PostCallCrmSignals.urgencyHigh ||
      s.priceObjection ||
      s.appointmentMentioned;
}

int postCallSignalsPriorityScore(PostCallCrmSignals s) {
  var sc = 0;
  if (s.followUpUrgency == PostCallCrmSignals.urgencyHigh) sc += 4;
  if (s.interestLevel == PostCallCrmSignals.interestHigh) sc += 3;
  if (s.priceObjection) sc += 2;
  if (s.appointmentMentioned) sc += 2;
  if (s.followUpUrgency == PostCallCrmSignals.urgencyMedium) sc += 1;
  return sc;
}

String postCallInterestLabelTr(String code) {
  switch (code) {
    case PostCallCrmSignals.interestHigh:
      return 'Yüksek';
    case PostCallCrmSignals.interestMedium:
      return 'Orta';
    case PostCallCrmSignals.interestLow:
      return 'Düşük';
    default:
      return 'Belirsiz';
  }
}

String postCallUrgencyLabelTr(String code) {
  switch (code) {
    case PostCallCrmSignals.urgencyHigh:
      return 'Yüksek';
    case PostCallCrmSignals.urgencyMedium:
      return 'Orta';
    case PostCallCrmSignals.urgencyLow:
      return 'Düşük';
    default:
      return 'Yok';
  }
}

bool _containsAny(String text, List<String> phrases) {
  final lower = text.toLowerCase();
  for (final p in phrases) {
    if (p.isEmpty) continue;
    if (lower.contains(p.toLowerCase())) return true;
    if (text.contains(p)) return true;
  }
  return false;
}

/// Özet metninden deterministik çıkarım. Asla throw etmez.
PostCallCrmSignals extractPostCallCrmSignals(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return PostCallCrmSignals.fallback();

  const highInterest = [
    'çok istekli',
    'çok ilgi',
    'ciddi alıcı',
    'hemen bak',
    'hemen almak',
    'sıcak fırsat',
    'çok heyecanlı',
    'hemen taşın',
    'hemen taşınmak',
    'satın almak istiyor',
    'kaçırmak istemiyor',
  ];
  const lowInterest = [
    'düşük ilgi',
    'kararsız',
    'düşünmüyor',
    'pek ilgi',
    'şüpheli',
    'sonra ararım',
    'takip listesi',
    'acil değil',
    'acelesi yok',
    'henüz karar vermedi',
    'karar vermedi',
  ];

  int score = 0;
  for (final p in highInterest) {
    if (_containsAny(text, [p])) score += 2;
  }
  for (final p in lowInterest) {
    if (_containsAny(text, [p])) score -= 2;
  }
  score = score.clamp(-4, 4);

  final anyInterestKeyword = highInterest.any((p) => _containsAny(text, [p])) ||
      lowInterest.any((p) => _containsAny(text, [p]));

  final String interestLevel;
  if (score >= 2) {
    interestLevel = PostCallCrmSignals.interestHigh;
  } else if (score <= -2) {
    interestLevel = PostCallCrmSignals.interestLow;
  } else if (score != 0 || anyInterestKeyword) {
    interestLevel = PostCallCrmSignals.interestMedium;
  } else {
    interestLevel = PostCallCrmSignals.interestUnknown;
  }

  const appointmentPhrases = [
    'randevu',
    'buluşma',
    'görüşme',
    'ofise gel',
    'ofise gelecek',
    'ziyaret',
    'yarın saat',
    'bugün saat',
    'salı günü',
    'çarşamba',
    'perşembe',
    'cumartesi',
    'pazartesi',
    'saat ',
    ' saatte ',
    'yüz yüze',
  ];
  final appointmentMentioned = _containsAny(text, appointmentPhrases);

  const pricePhrases = [
    'pahalı',
    'pahali',
    'bütçe yetmiyor',
    'butce yetmiyor',
    'fiyat yüksek',
    'indirim',
    'pazarlık',
    'ucuz değil',
    'ucuz degil',
    'daha düşük',
    'daha dusuk',
    'rakam yüksek',
    'beklentinin üstünde',
  ];
  final priceObjection = _containsAny(text, pricePhrases);

  const urgHigh = [
    'bugün',
    'yarın',
    'yarin',
    'acil',
    'hemen',
    'bu akşam',
    'bu aksam',
    '24 saat',
    '48 saat',
    'bu hafta sonu',
  ];
  const urgMedium = [
    'bu hafta',
    'önümüzdeki hafta',
    'onumuzdeki hafta',
    '2 gün',
    '3 gün',
    'birkaç gün',
    '15 gün',
    'on beş gün',
  ];
  const urgLow = [
    'acele yok',
    'zamanı var',
    'zamani var',
    '1 ay',
    'bir ay',
    'ileride',
    'sonra bakarız',
  ];

  String followUpUrgency;
  if (_containsAny(text, urgHigh)) {
    followUpUrgency = PostCallCrmSignals.urgencyHigh;
  } else if (_containsAny(text, urgMedium)) {
    followUpUrgency = PostCallCrmSignals.urgencyMedium;
  } else if (_containsAny(text, urgLow)) {
    followUpUrgency = PostCallCrmSignals.urgencyLow;
  } else {
    followUpUrgency = PostCallCrmSignals.urgencyNone;
  }

  final nextActionHint = _deriveNextActionHint(
    interestLevel: interestLevel,
    appointmentMentioned: appointmentMentioned,
    priceObjection: priceObjection,
    followUpUrgency: followUpUrgency,
  );

  return PostCallCrmSignals(
    interestLevel: interestLevel,
    nextActionHint: nextActionHint,
    appointmentMentioned: appointmentMentioned,
    priceObjection: priceObjection,
    followUpUrgency: followUpUrgency,
  );
}

String _deriveNextActionHint({
  required String interestLevel,
  required bool appointmentMentioned,
  required bool priceObjection,
  required String followUpUrgency,
}) {
  if (priceObjection) {
    return 'Fiyat ve bütçe beklentisini netleştirin; uygun alternatif portföy önerin.';
  }
  if (appointmentMentioned) {
    return 'Randevu veya yüz yüze görüşme için tarih ve saati kesinleştirin.';
  }
  if (followUpUrgency == PostCallCrmSignals.urgencyHigh) {
    return 'Kısa sürede (24–48 saat) dönüş veya sunum planlayın.';
  }
  if (interestLevel == PostCallCrmSignals.interestHigh) {
    return 'Uygun ilanları paylaşın veya detaylı sunum planlayın.';
  }
  if (interestLevel == PostCallCrmSignals.interestLow) {
    return 'Uzun vadeli takip notu; agresif kapanıştan kaçının.';
  }
  if (followUpUrgency == PostCallCrmSignals.urgencyMedium) {
    return 'Bu hafta içinde kontrol araması veya bilgi paylaşımı planlayın.';
  }
  if (interestLevel == PostCallCrmSignals.interestMedium) {
    return 'İhtiyaçları netleştirip bir sonraki adımı teyit edin.';
  }
  return 'Özet üzerinden standart takip zamanlaması belirleyin.';
}
