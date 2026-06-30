import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';

/// Çağrı yakalama ve kaydetme akışları için hafif audit izi.
///
/// Amaç:
/// - "çağrı geldi → öneri gösterildi → kaydedildi/ertelendi" zinciri izlenebilsin
/// - saha hatalarında kök neden hızlı bulunabilsin
/// - kullanıcı akışını bloklamasın (best-effort fire-and-forget)
class CallCaptureAuditService {
  CallCaptureAuditService._();
  static final CallCaptureAuditService instance = CallCaptureAuditService._();

  Future<void> logEvent({
    required String event,
    String? advisorId,
    String? phoneRaw,
    String? phoneKey,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await FirestoreService.ensureInitialized();
      final data = <String, dynamic>{
        'event': event,
        if (advisorId != null && advisorId.isNotEmpty) 'advisorId': advisorId,
        if (phoneRaw != null && phoneRaw.isNotEmpty) 'phoneRaw': phoneRaw,
        if (phoneKey != null && phoneKey.isNotEmpty) 'phoneKey': phoneKey,
        if (extra != null && extra.isNotEmpty) 'extra': extra,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection(AppConstants.colCallCaptureAudit)
          .add(data);
    } catch (e, st) {
      AppLogger.w('CallCaptureAuditService.logEvent($event)', e, st);
    }
  }
}

