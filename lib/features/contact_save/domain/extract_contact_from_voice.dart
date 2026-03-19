import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';

/// Sesli komuttan isim, telefon, not çıkarır (Türkçe; AI yardımı ile rehbere kayıt).
ContactSaveRequest? extractContactFromVoice(String transcript) {
  final t = transcript.trim();
  if (t.isEmpty) return null;

  String? name;
  String? phone;
  String? note;

  // Örnek: "Ahmet Yılmaz", "Ahmet Yılmaz diye kaydet", "isim Ahmet Yılmaz"
  final namePatterns = [
    RegExp(r'(?:isim|ad|adı)\s*[:\s]*([^\n,\.]+?)(?:\s+telefon|\s+numara|,|\.|$)', caseSensitive: false),
    RegExp(r'^([A-Za-zÇçĞğİıÖöŞşÜü\s]+?)(?:\s+telefon|\s+numara|\s+0\d|\s+5\d{2})', caseSensitive: false),
    RegExp(r'(?:kaydet|ekle|yaz)\s+([A-Za-zÇçĞğİıÖöŞşÜü\s]+?)(?:\s+telefon|$)', caseSensitive: false),
  ];
  for (final re in namePatterns) {
    final m = re.firstMatch(t);
    if (m != null) {
      name = m.group(1)?.trim();
      if (name != null && name.length >= 2) break;
    }
  }
  if (name == null) {
    final firstPart = t.split(RegExp(r'\s+')).where((s) => s.length > 1).take(2).join(' ');
    if (firstPart.length >= 2) name = firstPart;
  }

  // Telefon: 05xx xxx xx xx, 5xx xxx xx xx, +90 5xx
  final phoneMatch = RegExp(r'(?:\+90\s*)?(0?\s*5\d{2}\s*\d{3}\s*\d{2}\s*\d{2})').firstMatch(t);
  if (phoneMatch != null) {
    phone = phoneMatch.group(1)?.replaceAll(RegExp(r'\s'), '') ?? '';
    if (phone.length >= 10) phone = phone.replaceFirst(RegExp(r'^0?'), '0');
  }
  if (phone == null || phone.length < 10) {
    final anyNum = RegExp(r'(\d{10,14})').firstMatch(t);
    if (anyNum != null) phone = anyNum.group(1);
  }

  // Not: "not ...", "açıklama ..." veya cümlenin geri kalanı
  final noteMatch = RegExp(r'(?:not|açıklama|notlar)\s*[:\s]*([^\n]+)', caseSensitive: false).firstMatch(t);
  if (noteMatch != null) {
    note = noteMatch.group(1)?.trim();
  } else if (t.length > 50 && (name != null || phone != null)) {
    note = t.length > 120 ? '${t.substring(0, 117)}...' : t;
  }

  if (name == null && phone == null) return null;
  return ContactSaveRequest(
    fullName: name ?? 'İsimsiz',
    primaryPhone: phone ?? '',
    note: note?.isNotEmpty == true ? note : null,
  );
}
