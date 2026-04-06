import 'dart:convert';

/// Çevrimdışı yazılamayan minimum handoff kaydı — yerel kuyruk öğesi.
class PendingHandoffOutboundItem {
  const PendingHandoffOutboundItem({
    required this.localDraftId,
    required this.advisorId,
    this.customerId,
    required this.phoneNumber,
    required this.startedFromScreen,
    required this.createdAtMs,
  });

  /// Taslak `callSessionId` (`local_…`); idempotent Firestore doc id türetmek için anahtar.
  final String localDraftId;
  final String advisorId;
  final String? customerId;
  final String phoneNumber;
  final String startedFromScreen;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
        'localDraftId': localDraftId,
        'advisorId': advisorId,
        if (customerId != null && customerId!.isNotEmpty) 'customerId': customerId,
        'phoneNumber': phoneNumber,
        'startedFromScreen': startedFromScreen,
        'createdAtMs': createdAtMs,
      };

  static PendingHandoffOutboundItem? tryFromJson(Map<String, dynamic> m) {
    final localDraftId = m['localDraftId'] as String?;
    final advisorId = m['advisorId'] as String?;
    final phone = m['phoneNumber'] as String?;
    if (localDraftId == null ||
        localDraftId.isEmpty ||
        advisorId == null ||
        advisorId.isEmpty ||
        phone == null ||
        phone.isEmpty) {
      return null;
    }
    return PendingHandoffOutboundItem(
      localDraftId: localDraftId,
      advisorId: advisorId,
      customerId: m['customerId'] as String?,
      phoneNumber: phone,
      startedFromScreen: (m['startedFromScreen'] as String?) ?? 'unknown',
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static List<PendingHandoffOutboundItem> listFromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => tryFromJson(e as Map<String, dynamic>))
          .whereType<PendingHandoffOutboundItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<PendingHandoffOutboundItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
