import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:flutter/foundation.dart';

/// Telefonu uygulama biçimine çevirir: `05XXXXXXXXX` (11 hane) veya geçersizse `null`.
///
/// Kabul edilen kaynak örnekleri: `05321234567`, `0532 123 45 67`, `+90 532 123 45 67`,
/// `5321234567`, `90 532 123 45 67`, `905321234567`.
String? normalizeTurkishMobile(String? raw) {
  if (raw == null) return null;
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return null;

  var x = d;
  if (x.length >= 12 && x.startsWith('90') && x[2] == '5') {
    x = x.substring(2);
  } else if (x.length >= 13 && x.startsWith('090')) {
    x = x.substring(1);
  }
  if (x.length == 11 && x.startsWith('05') && x[2] == '5') {
    return RegExp(r'^05\d{9}$').hasMatch(x) ? x : null;
  }
  if (x.length == 10 && x.startsWith('5')) {
    final v = '0$x';
    return RegExp(r'^05\d{9}$').hasMatch(v) ? v : null;
  }
  if (x.length == 12 && x.startsWith('90')) {
    final rest = x.substring(2);
    if (rest.length == 10 && rest.startsWith('5')) {
      final v = '0$rest';
      return RegExp(r'^05\d{9}$').hasMatch(v) ? v : null;
    }
  }
  return null;
}

/// Metinden ilk geçerli Türk cep numarasını bulur (uzunluk / +90 varyantları).
String? findFirstTurkishMobileInText(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;

  final labeled = RegExp(
    r'(?:telefonu?|numarası|numara|cep|gsm)\s*[:\s]*(\+?90[\d\s\-]*?5\d{2}[\d\s\-]*\d{3}[\d\s\-]*\d{2}[\d\s\-]*\d{2})',
    caseSensitive: false,
  ).firstMatch(t);
  if (labeled != null) {
    final n = normalizeTurkishMobile(labeled.group(1));
    if (n != null) return n;
  }

  final loose = RegExp(
    r'(?:\+?90\s*)?(?:0?\s*)?5\d{2}[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}',
    caseSensitive: false,
  );
  for (final m in loose.allMatches(t)) {
    final n = normalizeTurkishMobile(m.group(0));
    if (n != null) return n;
  }

  final digitChunks = RegExp(r'\+?[\d\s\-]{10,22}').allMatches(t);
  for (final m in digitChunks) {
    final n = normalizeTurkishMobile(m.group(0));
    if (n != null) return n;
  }

  final onlyDigits = t.replaceAll(RegExp(r'\D'), '');
  for (var i = 0; i <= onlyDigits.length - 10; i++) {
    for (var len = 10; len <= 13 && i + len <= onlyDigits.length; len++) {
      final n = normalizeTurkishMobile(onlyDigits.substring(i, i + len));
      if (n != null) return n;
    }
  }
  return null;
}

/// Ses metninden çıkarılan müşteri + hangi alanların boş kaldığı (vurgu / gözden geçirme).
class VoiceContactExtraction {
  const VoiceContactExtraction({
    required this.request,
    this.nameMissing = false,
    this.phoneMissing = false,
    this.parseNeedsReview = false,
  });

  final ContactSaveRequest request;
  final bool nameMissing;
  final bool phoneMissing;

  /// Yalnızca sezgisel / eksik etiketli ayrıştırma.
  final bool parseNeedsReview;
}

/// Eski API — [parseVoiceContact] kullanın.
ContactSaveRequest? extractContactFromVoice(String transcript) =>
    parseVoiceContact(transcript)?.request;

/// Doğal Türkçe konuşma ve kısmen yapılandırılmış ifadeler için ayrıştırma.
VoiceContactExtraction? parseVoiceContact(String transcript) {
  final t = transcript.trim();
  if (t.isEmpty) return null;

  String? name;
  String? phone;
  String? note;
  var nameMissing = false;
  var phoneMissing = false;
  var parseNeedsReview = false;
  var heuristicNameUsed = false;
  var remainderNoteUsed = false;
  var explicitNoteFromPattern = false;

  String working = t;

  // --- Telefon önce (metinden çıkarmak için)
  phone = findFirstTurkishMobileInText(working);
  if (phone != null) {
    working = _stripPhoneOccurrences(working, phone);
  }

  // --- Ad + soyad ayrı
  final adSoyad = RegExp(
    r'adı\s*[:\s]*([^,]+?)\s*,\s*soyadı\s*[:\s]*([^\n,\.]+?)(?=\s+telefon|\s+numara|\s+not|$)',
    caseSensitive: false,
  ).firstMatch(t);
  if (adSoyad != null) {
    final a = adSoyad.group(1)?.trim() ?? '';
    final s = adSoyad.group(2)?.trim() ?? '';
    if (a.isNotEmpty && s.isNotEmpty) {
      name = '$a $s';
      working = working.replaceAll(adSoyad.group(0)!, ' ');
    }
  }

  // --- Etiketli isim
  if (name == null || name.isEmpty) {
    final namePatterns = <RegExp>[
      RegExp(
        r'müşteri\s+adı\s*[:\s]*([^\n,\.]+?)(?=\s+telefon|\s+numara|\s+telefonu|\s+not|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:^|\s)müşteri\s+(?!adı\s)([A-Za-zÇçĞğİıÖöŞşÜü][A-Za-zÇçĞğİıÖöŞşÜü\s]{1,48}?)(?=\s*(?:telefon|numara|numarası|telefonu|not|notu|sıcak)|,|\s*$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:adı|isim|ad\s*şu|isim\s*şu)\s*[:\s]*([^\n,\.]+?)(?=\s+telefon|\s+numara|\s+telefonu|\s+not|\s+notu|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:isim|ad|adı)\s*[:\s]*([^\n,\.]+?)(?:\s+telefon|\s+numara|\s+telefonu|,|\.|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'^([A-Za-zÇçĞğİıÖöŞşÜü][A-Za-zÇçĞğİıÖöŞşÜü\s]{1,40}?)\s*,\s*(?:numarası|telefonu)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:kaydet|ekle|yaz)\s+([A-Za-zÇçĞğİıÖöŞşÜü\s]+?)(?:\s+telefon|\s+numara|$)',
        caseSensitive: false,
      ),
    ];
    for (final re in namePatterns) {
      final m = re.firstMatch(t);
      if (m != null) {
        final cand = m.group(1)?.trim();
        if (cand != null && cand.length >= 2 && !_looksLikePhoneFragment(cand)) {
          name = cand;
          break;
        }
      }
    }
  }

  // --- Etiketli not (notu / not)
  final notePatterns = <RegExp>[
    RegExp(
      r'notu\s*[:\s]+([^\n]+?)(?=\s*(?:telefon|numara|numarası|telefonu)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:not|açıklama|notlar)\s*[:\s]*([^\n]+)',
      caseSensitive: false,
    ),
  ];
  for (final re in notePatterns) {
    final m = re.firstMatch(t);
    if (m != null) {
      final n = m.group(1)?.trim();
      if (n != null && n.isNotEmpty) {
        note = n;
        explicitNoteFromPattern = true;
        break;
      }
    }
  }

  // --- "Ahmet Yılmaz sıcak müşteri, telefonu ..." — isim + not ayrımı
  if (name == null || name.isEmpty) {
    final natural = RegExp(
      r'^([A-Za-zÇçĞğİıÖöŞşÜü][A-Za-zÇçĞğİıÖöŞşÜü\s]{1,40}?)\s+([^\n,]+?)\s*,\s*(?:telefonu|numarası)',
      caseSensitive: false,
    ).firstMatch(t);
    if (natural != null) {
      final n1 = natural.group(1)?.trim() ?? '';
      final n2 = natural.group(2)?.trim() ?? '';
      if (n1.split(RegExp(r'\s+')).length >= 2) {
        name = n1;
        if (note == null && n2.isNotEmpty) note = n2;
      }
    }
  }

  // --- Heuristic isim (telefon ve anahtar kelimeler çıkarılmış working üzerinden)
  if (name == null || name.isEmpty) {
    final h = _heuristicPersonName(working);
    if (h != null) {
      name = h;
      heuristicNameUsed = true;
    }
  }

  // --- Heuristic not = kalan metin (isim ve telefon çıkarılmış)
  if (note == null || note.isEmpty) {
    final remainder = _remainderAfterNameAndPhone(t, name, phone);
    if (remainder.trim().length >= 3) {
      note = remainder.trim();
      remainderNoteUsed = true;
    }
  }

  if (phone == null) {
    phoneMissing = true;
  }
  if (name == null || name.trim().length < 2) {
    nameMissing = true;
  }

  parseNeedsReview = nameMissing ||
      phoneMissing ||
      heuristicNameUsed ||
      (remainderNoteUsed && !explicitNoteFromPattern);

  final resolvedName =
      (name != null && name.trim().length >= 2) ? name.trim() : '';
  final resolvedPhone = phone ?? '';

  if (resolvedName.isEmpty && resolvedPhone.isEmpty && (note == null || note.isEmpty)) {
    return null;
  }

  return VoiceContactExtraction(
    request: ContactSaveRequest(
      fullName: resolvedName,
      primaryPhone: resolvedPhone,
      note: (note != null && note.isNotEmpty) ? note : null,
    ),
    nameMissing: nameMissing,
    phoneMissing: phoneMissing,
    parseNeedsReview: parseNeedsReview,
  );
}

bool _looksLikePhoneFragment(String s) => RegExp(r'^\d').hasMatch(s.trim());

String _stripPhoneOccurrences(String text, String normalizedPhone) {
  var s = text;
  final patterns = [
    RegExp(
      r'(?:telefonu?|numarası|numara|cep|gsm)\s*[:\s]*(?:\+?90\s*)?(?:0?\s*)?5\d{2}[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}',
      caseSensitive: false,
    ),
    RegExp(r'\+?90[\d\s\-]{8,20}'),
    RegExp(r'0?5\d{2}[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}'),
  ];
  for (final re in patterns) {
    s = s.replaceAll(re, ' ');
  }
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _heuristicPersonName(String working) {
  final cleaned = working
      .replaceAll(
        RegExp(
          r'\b(telefon|numara|numarası|telefonu|müşteri|not|notu|açıklama|cep|gsm|sıcak)\b',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'[,;]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.length < 3) return null;

  final tokens = cleaned.split(' ').where((w) => w.isNotEmpty).toList();
  final nameLike = <String>[];
  for (final w in tokens) {
    if (nameLike.length >= 3) break;
    if (RegExp(r'^[A-Za-zÇçĞğİıÖöŞşÜü]{2,}$').hasMatch(w)) {
      if (!RegExp(r'^\d').hasMatch(w)) nameLike.add(w);
    } else {
      break;
    }
  }
  if (nameLike.length >= 2) return nameLike.take(2).join(' ');
  if (nameLike.length == 1 && tokens.length >= 2) {
    final second = tokens[1];
    if (RegExp(r'^[A-Za-zÇçĞğİıÖöŞşÜü]{2,}$').hasMatch(second)) {
      return '${nameLike[0]} $second';
    }
  }
  if (nameLike.length == 1 && nameLike[0].length >= 3) return nameLike[0];
  return null;
}

String _remainderAfterNameAndPhone(String original, String? name, String? phone) {
  var s = original;
  if (phone != null) {
    s = _stripPhoneOccurrences(s, phone);
  }
  if (name != null && name.isNotEmpty) {
    final esc = RegExp.escape(name);
    s = s.replaceFirst(RegExp(esc, caseSensitive: false), ' ');
  }
  s = s.replaceAll(
    RegExp(
      r'\b(telefon|numara|numarası|telefonu|müşteri|adı|soyadı|not|notu|açıklama)\b',
      caseSensitive: false,
    ),
    ' ',
  );
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Debug: sesli müşteri ayrıştırma özeti (yalnızca debug/profile).
void logVoiceContactParseDebug({
  required String rawText,
  required VoiceContactExtraction? extraction,
  required bool shouldReviewStt,
}) {
  if (kReleaseMode) return;
  final e = extraction;
  final name = e?.request.fullName ?? '';
  final phone = e?.request.primaryPhone ?? '';
  final note = e?.request.note ?? '';
  final combinedReview = shouldReviewStt ||
      (e?.parseNeedsReview ?? false) ||
      (e?.nameMissing ?? false) ||
      (e?.phoneMissing ?? false);
  final line =
      '[VoiceContactParse] raw="${_oneLine(rawText)}" '
      'name="$name" phone="$phone" note="${_oneLine(note)}" '
      'nameMissing=${e?.nameMissing} phoneMissing=${e?.phoneMissing} '
      'parseNeedsReview=${e?.parseNeedsReview} shouldReviewStt=$shouldReviewStt combinedReview=$combinedReview';
  debugPrint(line);
  AppLogger.d(line);
}

String _oneLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
