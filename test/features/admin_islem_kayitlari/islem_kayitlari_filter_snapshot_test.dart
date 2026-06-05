import 'package:emlakmaster_mobile/core/models/invite_doc.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/data/audit_log_entry.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_filter.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:flutter_test/flutter_test.dart';

AuditLogEntry _audit({
  required String id,
  String action = '',
  String message = '',
  String actorId = '',
  String severity = '',
  DateTime? at,
  String teamId = '',
  String consultantId = '',
}) {
  return AuditLogEntry(
    id: id,
    raw: const {},
    action: action,
    actorId: actorId,
    message: message,
    severity: severity,
    teamId: teamId,
    consultantId: consultantId,
    occurredAt: at,
  );
}

InviteDoc _invite({
  required String id,
  String email = 'a@test.com',
  DateTime? at,
}) {
  return InviteDoc(
    id: id,
    email: email,
    role: 'agent',
    createdBy: 'admin1',
    createdAt: at,
  );
}

void main() {
  final now = DateTime(2026, 5, 27, 12, 0);

  group('islem kayitlari snapshot', () {
    test('merges audit logs and invites sorted by time', () {
      final snapshot = computeIslemKayitlariSnapshot(
        auditLogs: [
          _audit(
            id: 'a1',
            action: 'team_update',
            message: 'Ekip güncellendi',
            at: now.subtract(const Duration(hours: 2)),
            teamId: 't1',
          ),
        ],
        invites: [
          _invite(id: 'i1', at: now.subtract(const Duration(minutes: 30))),
        ],
        consultants: const [],
        now: now,
      );

      expect(snapshot.rows.length, 2);
      expect(snapshot.rows.first.id, 'invite:i1');
      expect(snapshot.hasInvites, isTrue);
      expect(snapshot.hasAuditLogs, isTrue);
    });

    test('strip counts only real categories', () {
      final snapshot = computeIslemKayitlariSnapshot(
        auditLogs: [
          _audit(
            id: 'c1',
            action: 'role_change',
            severity: 'critical',
            at: now.subtract(const Duration(hours: 1)),
          ),
          _audit(
            id: 'c2',
            action: 'consultant_update',
            consultantId: 'u1',
            at: now.subtract(const Duration(hours: 3)),
          ),
        ],
        invites: [_invite(id: 'i1', at: now.subtract(const Duration(hours: 5)))],
        consultants: const [],
        now: now,
      );

      expect(snapshot.strip.last24hCount, 3);
      expect(snapshot.strip.criticalCount, 1);
      expect(snapshot.strip.inviteCount, 1);
      expect(snapshot.strip.consultantActionCount, 1);
    });

    test('empty state is honest about coverage', () {
      final snapshot = computeIslemKayitlariSnapshot(
        auditLogs: const [],
        invites: const [],
        consultants: const [],
        now: now,
      );

      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.coverageNote, contains('Henüz'));
    });
  });

  group('islem kayitlari filter', () {
    late IslemKayitlariPageSnapshot snapshot;

    setUp(() {
      snapshot = computeIslemKayitlariSnapshot(
        auditLogs: [
          _audit(
            id: 'a1',
            action: 'team_update',
            message: 'Alpha ekibi',
            at: now.subtract(const Duration(hours: 1)),
            teamId: 't1',
          ),
          _audit(
            id: 'a2',
            action: 'role_change',
            severity: 'critical',
            message: 'Yetki değişimi',
            at: now.subtract(const Duration(hours: 2)),
          ),
        ],
        invites: [_invite(id: 'i1', email: 'new@test.com', at: now)],
        consultants: const [],
        now: now,
      );
    });

    test('search matches title and actor', () {
      final out = filterIslemKayitlariRows(
        source: snapshot.rows,
        searchQuery: 'alpha',
        filter: IslemKayitlariFilter.all,
        now: now,
      );
      expect(out.length, 1);
      expect(out.first.title, contains('Alpha'));
    });

    test('invite filter', () {
      final out = filterIslemKayitlariRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: IslemKayitlariFilter.invite,
        now: now,
      );
      expect(out.every((r) => r.category == IslemKayitlariCategory.invite), isTrue);
    });

    test('critical filter', () {
      final out = filterIslemKayitlariRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: IslemKayitlariFilter.critical,
        now: now,
      );
      expect(out.length, 1);
      expect(out.first.severity, IslemKayitlariSeverity.critical);
    });

    test('last24h filter', () {
      final out = filterIslemKayitlariRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: IslemKayitlariFilter.last24h,
        now: now,
      );
      expect(out, isNotEmpty);
    });
  });
}
