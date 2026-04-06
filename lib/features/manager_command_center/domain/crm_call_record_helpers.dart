import 'package:cloud_firestore/cloud_firestore.dart';

/// CRM çağrı kaydı yardımcıları — operatör/telekom kesinliği iddia etmez.
abstract final class CrmCallRecordHelpers {
  CrmCallRecordHelpers._();

  static bool isHandoffPending(Map<String, dynamic> data) =>
      (data['outcome'] as String?) == 'handoff_pending';

  static bool hasCaptureCompleted(Map<String, dynamic> data) =>
      data['captureCompletedAt'] != null;

  static bool isSystemHandoff(Map<String, dynamic> data) =>
      (data['source'] as String?) == 'system_handoff' ||
      data['handoffMode'] == true;

  static String agentIdOf(Map<String, dynamic> data) =>
      (data['agentId'] as String?)?.trim().isNotEmpty == true
          ? data['agentId'] as String
          : (data['advisorId'] as String? ?? '');

  static String? customerIdOf(Map<String, dynamic> data) {
    final c = data['customerId'] as String?;
    if (c == null || c.trim().isEmpty) return null;
    return c.trim();
  }

  static DateTime? createdAtOf(Map<String, dynamic> data) {
    final c = data['createdAt'];
    if (c is Timestamp) return c.toDate();
    return null;
  }

  /// Görünen sonuç: hızlı yakalama etiketi veya outcome kodu.
  static String outcomeDisplayTr(
    Map<String, dynamic> data,
    Map<String, String> codeLabels,
  ) {
    final quick = data['quickOutcomeLabelTr'] as String?;
    if (quick != null && quick.trim().isNotEmpty) return quick.trim();
    final o = data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
    if (o.isEmpty) return '—';
    return codeLabels[o] ?? o;
  }

  static String sourceDisplayTr(Map<String, dynamic> data) {
    final s = data['source'] as String? ?? '';
    switch (s) {
      case 'system_handoff':
        return 'Telefon devret (CRM oturumu)';
      case 'device':
        return 'Cihaz günlüğü';
      default:
        return s.isEmpty ? 'CRM kaydı' : s;
    }
  }

  static String captureStatusTr(Map<String, dynamic> data) {
    if (hasCaptureCompleted(data)) return 'Kayıt tamamlandı';
    if (isHandoffPending(data)) return 'Sonuç bekleniyor';
    return 'Kısmi / diğer';
  }
}
