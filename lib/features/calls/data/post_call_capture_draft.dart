import 'dart:convert';

/// Gerçek telefon handoff sonrası bekleyen hızlı kayıt (yerel taslak).
class PostCallCaptureDraft {
  /// Yerel taslak anahtarı — Firestore `calls` dokümanı henü yok.
  static const String localPrefix = 'local_';

  const PostCallCaptureDraft({
    required this.callSessionId,
    required this.localRecordId,
    this.customerId,
    required this.phone,
    required this.startedFromScreen,
    required this.createdAtMs,
    this.dismissedFromStrip = false,
    /// `false` ise [callSessionId] yalnızca yerel takip anahtarıdır (`local_…`); Firestore `calls` dokümanı handoff sırasında oluşturulmamıştır.
    this.crmSessionTracked = true,
  });

  /// Hive / offline-first ana kayıt kimliği — [callSessionId] değişse bile sabit kalır (`local_…`).
  final String localRecordId;

  final String callSessionId;
  final String? customerId;
  final String phone;
  final String startedFromScreen;
  final int createdAtMs;
  final bool dismissedFromStrip;
  /// CRM handoff oturumu Firestore'a yazıldıysa `true`; ağ/kural hatasında `false` (arama yine de yapılabilir).
  final bool crmSessionTracked;

  /// `calls/{id}` zaten var (handoff veya otomatik minimum kayıt); hızlı kayıtta merge kullanılır.
  bool get hasFirestoreCallDoc => !callSessionId.startsWith(localPrefix);

  PostCallCaptureDraft copyWith({
    String? callSessionId,
    String? localRecordId,
    String? customerId,
    String? phone,
    String? startedFromScreen,
    int? createdAtMs,
    bool? dismissedFromStrip,
    bool? crmSessionTracked,
  }) {
    return PostCallCaptureDraft(
      callSessionId: callSessionId ?? this.callSessionId,
      localRecordId: localRecordId ?? this.localRecordId,
      customerId: customerId ?? this.customerId,
      phone: phone ?? this.phone,
      startedFromScreen: startedFromScreen ?? this.startedFromScreen,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      dismissedFromStrip: dismissedFromStrip ?? this.dismissedFromStrip,
      crmSessionTracked: crmSessionTracked ?? this.crmSessionTracked,
    );
  }

  Map<String, dynamic> toJson() => {
        'callSessionId': callSessionId,
        'localRecordId': localRecordId,
        if (customerId != null && customerId!.isNotEmpty) 'customerId': customerId,
        'phone': phone,
        'startedFromScreen': startedFromScreen,
        'createdAtMs': createdAtMs,
        'dismissedFromStrip': dismissedFromStrip,
        'crmSessionTracked': crmSessionTracked,
      };

  static PostCallCaptureDraft? tryFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final id = m['callSessionId'] as String?;
      final phone = m['phone'] as String?;
      if (id == null || id.isEmpty || phone == null || phone.isEmpty) return null;
      final createdMs = (m['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      final localRid = (m['localRecordId'] as String?)?.trim();
      final resolvedLocal = (localRid != null && localRid.isNotEmpty)
          ? localRid
          : (id.startsWith(localPrefix)
              ? id
              : '$localPrefix$createdMs');
      return PostCallCaptureDraft(
        callSessionId: id,
        localRecordId: resolvedLocal,
        customerId: m['customerId'] as String?,
        phone: phone,
        startedFromScreen: (m['startedFromScreen'] as String?) ?? 'unknown',
        createdAtMs: createdMs,
        dismissedFromStrip: m['dismissedFromStrip'] as bool? ?? false,
        crmSessionTracked: m['crmSessionTracked'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }
}
