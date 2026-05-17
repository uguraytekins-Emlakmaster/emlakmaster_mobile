/// CRM çağrı kaydı listeleri için görünen başlık / meta yardımcıları (veri modeli değişmez).
abstract final class CrmCallRecordDisplay {
  CrmCallRecordDisplay._();

  /// TR görünümü için telefon biçimlendirir; tanınmayan biçimde ham değeri döner.
  static String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '0${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
    }
    if (digits.length == 12 && digits.startsWith('90')) {
      return '+90 ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
    }
    return phone;
  }

  static String ellipsedMiddle(
    String value, {
    int head = 4,
    int tail = 4,
  }) {
    final v = value.trim();
    if (v.length <= head + tail + 1) return v;
    return '${v.substring(0, head)}…${v.substring(v.length - tail)}';
  }

  /// Firestore çağrı belgesinde ara sıra bulunan iletişim görünen adı.
  static String? contactNameFromCallData(Map<String, dynamic> data) {
    for (final key in <String>[
      'contactDisplayName',
      'contactName',
      'customerDisplayName',
      'customerName',
      'callerName',
    ]) {
      final v = data[key] as String?;
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// L1 başlık: müşteri adı → iletişim adı → biçimli telefon → yumuşak geri dönüş.
  static String primaryTitle({
    String? customerFullName,
    String? contactDisplayName,
    String? rawPhone,
  }) {
    final name = customerFullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final contact = contactDisplayName?.trim();
    if (contact != null && contact.isNotEmpty) return contact;
    final raw = rawPhone ?? '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) return formatPhone(raw);
    return 'Bilinmeyen kişi';
  }

  /// Başlık telefon iken alt satırda tekrar göstermeyi önlemek için.
  static bool shouldShowPhoneUnderTitle({
    required String title,
    required String formattedPhone,
  }) {
    final p = formattedPhone.trim();
    if (p.isEmpty || p == '—') return false;
    if (title.trim() == p.trim()) return false;
    return true;
  }

  /// Danışman satırı: kimlik yerine okunur isim; yedekte kısa “Danışman”.
  static String advisorContext({
    required String advisorAgentId,
    String? currentUid,
    Map<String, String> agentNames = const {},
  }) {
    final id = advisorAgentId.trim();
    if (id.isEmpty) return 'Danışman bilgisi yok';
    if (currentUid != null && id == currentUid) return 'Sen';
    final n = agentNames[id]?.trim();
    if (n != null && n.isNotEmpty && n != id) return n;
    return 'Danışman';
  }

  /// Tarih / süre ile tek satır bağlam (L3).
  static String contextLine({
    required String advisorPart,
    required String dateTime,
    String? duration,
  }) {
    final dur = duration?.trim();
    final hasDur = dur != null && dur.isNotEmpty && dur != '—';
    final dt = dateTime.trim();
    final hasDt = dt.isNotEmpty && dt != '—';
    if (hasDt && hasDur) return '$advisorPart · $dt · $dur';
    if (hasDt) return '$advisorPart · $dt';
    if (hasDur) return '$advisorPart · $dur';
    return advisorPart;
  }

  /// Çağrı belgesinden ilk anlamlı not / özet (liste önizlemesi).
  static String? notePreviewFromFirestoreData(
    Map<String, dynamic> data, {
    int maxLen = 120,
  }) {
    String? pick(String key) {
      final v = data[key] as String?;
      if (v == null || v.trim().isEmpty) return null;
      return v.trim();
    }
    for (final key in <String>[
      'quickCaptureNote',
      'quickNote',
      'postCallSummaryText',
      'note',
    ]) {
      final s = pick(key);
      if (s != null) {
        if (maxLen > 0 && s.length > maxLen) {
          return '${s.substring(0, maxLen)}…';
        }
        return s;
      }
    }
    return null;
  }

  /// L4: kayıt ve müşteri kimlikleri — düşük öncelik metin.
  static String? technicalFootnote({
    String? firestoreDocId,
    String? customerId,
  }) {
    final parts = <String>[];
    if (firestoreDocId != null && firestoreDocId.trim().isNotEmpty) {
      parts.add('CRM kaydı: ${ellipsedMiddle(firestoreDocId.trim())}');
    }
    if (customerId != null && customerId.trim().isNotEmpty) {
      parts.add('Müşteri: ${ellipsedMiddle(customerId.trim())}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
