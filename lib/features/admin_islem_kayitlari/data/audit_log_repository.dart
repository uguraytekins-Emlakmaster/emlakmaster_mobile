import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/models/invite_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/data/audit_log_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _auditLogLimit = 200;
const _inviteLimit = 100;

/// `audit_logs` stream — yönetici okuma yetkisi Firestore kurallarında.
final auditLogsStreamProvider = StreamProvider.autoDispose<List<AuditLogEntry>>((ref) {
  return AuditLogRepository.watchAuditLogs();
});

/// `invites` stream — gerçek davet kayıtları (denetim tamamlayıcısı).
final adminInvitesStreamProvider = StreamProvider.autoDispose<List<InviteDoc>>((ref) {
  return AuditLogRepository.watchInvites();
});

abstract final class AuditLogRepository {
  AuditLogRepository._();

  static Stream<List<AuditLogEntry>> watchAuditLogs() async* {
    await FirestoreService.ensureInitialized();
    if (!FirestoreService.isFirestoreReady) {
      yield const [];
      return;
    }

    final col = FirebaseFirestore.instance.collection(AppConstants.colAuditLogs);

    yield* col.limit(_auditLogLimit).snapshots().map((snap) {
      final out = _mapAuditSnapshot(snap);
      out.sort((a, b) {
        final aAt = a.occurredAt;
        final bAt = b.occurredAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });
      return out;
    });
  }

  static Stream<List<InviteDoc>> watchInvites() async* {
    await FirestoreService.ensureInitialized();
    if (!FirestoreService.isFirestoreReady) {
      yield const [];
      return;
    }

    final col = FirebaseFirestore.instance.collection(AppConstants.colInvites);

    yield* col.limit(_inviteLimit).snapshots().map((snap) {
      final out = <InviteDoc>[];
      for (final doc in snap.docs) {
        final invite = InviteDoc.fromFirestore(doc.id, doc.data());
        if (invite != null) out.add(invite);
      }
      out.sort((a, b) {
        final aAt = a.createdAt;
        final bAt = b.createdAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });
      return out;
    });
  }

  static List<AuditLogEntry> _mapAuditSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final out = <AuditLogEntry>[];
    for (final doc in snap.docs) {
      final entry = AuditLogEntry.fromFirestore(doc.id, doc.data());
      if (entry != null) out.add(entry);
    }
    return out;
  }
}
