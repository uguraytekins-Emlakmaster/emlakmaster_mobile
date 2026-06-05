// ignore_for_file: avoid_redundant_argument_values

import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_filter.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_uyelikler/presentation/utils/uyelikler_types.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_invite_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_membership_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

OfficeInvite _invite({
  required String id,
  String code = 'CODE1234',
  OfficeRole role = OfficeRole.consultant,
  int maxUses = 1,
  int usedCount = 0,
  bool isActive = true,
  DateTime? expiresAt,
  DateTime? createdAt,
  String createdBy = 'admin1',
}) {
  return OfficeInvite(
    id: id,
    officeId: 'o1',
    code: code,
    createdBy: createdBy,
    expiresAt: expiresAt,
    maxUses: maxUses,
    usedCount: usedCount,
    roleToAssign: role,
    isActive: isActive,
    createdAt: createdAt,
  );
}

OfficeMembership _member({
  required String userId,
  OfficeRole role = OfficeRole.consultant,
  MembershipStatus status = MembershipStatus.active,
  DateTime? joinedAt,
}) {
  return OfficeMembership(
    id: '${userId}_o1',
    officeId: 'o1',
    userId: userId,
    role: role,
    status: status,
    joinedAt: joinedAt,
  );
}

UserDoc _user(String uid, {String? name, String? email}) =>
    UserDoc(uid: uid, role: 'agent', name: name, email: email);

void main() {
  final now = DateTime(2026, 5, 31, 12, 0);

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('uyelikler snapshot', () {
    test('merges invites and members, sorts intervention first', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: [
          _invite(id: 'i1', createdAt: now.subtract(const Duration(hours: 1))),
        ],
        members: [
          _member(
            userId: 'u1',
            status: MembershipStatus.active,
            joinedAt: now.subtract(const Duration(days: 2)),
          ),
          _member(
            userId: 'u2',
            status: MembershipStatus.suspended,
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        directory: const [],
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );

      expect(snapshot.rows.length, 3);
      // Müdahale gereken (suspended) ilk sırada.
      expect(snapshot.rows.first.needsAction, isTrue);
      expect(snapshot.hasInvites, isTrue);
      expect(snapshot.hasMembers, isTrue);
    });

    test('strip counts only grounded values', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: [
          _invite(id: 'i1', usedCount: 0), // bekleyen
          _invite(id: 'i2', usedCount: 1, maxUses: 3), // kabul (kısmi)
          _invite(id: 'i3', isActive: false), // süresi dolan (pasif)
          _invite(
            id: 'i4',
            expiresAt: now.subtract(const Duration(days: 1)),
          ), // süresi dolan (expired)
        ],
        members: [
          _member(userId: 'u1', status: MembershipStatus.active),
          _member(userId: 'u2', status: MembershipStatus.suspended),
          _member(userId: 'u3', status: MembershipStatus.removed),
        ],
        directory: const [],
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );

      expect(snapshot.strip.pendingInvites, 1);
      expect(snapshot.strip.acceptedInvites, 1);
      expect(snapshot.strip.expiredInvites, 2);
      expect(snapshot.strip.activeMembers, 1);
      expect(snapshot.strip.interventionCount, 2);
      expect(snapshot.strip.totalInvites, 4);
      expect(snapshot.strip.totalMembers, 3);
    });

    test('resolves member name from directory, honest fallback otherwise', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: const [],
        members: [
          _member(
            userId: 'known',
            status: MembershipStatus.active,
            joinedAt: now.subtract(const Duration(days: 3)),
          ),
          _member(userId: 'unknownuserid123', status: MembershipStatus.active),
        ],
        directory: [_user('known', name: 'Ada Lovelace')],
        currentUid: 'me',
        actorRole: OfficeRole.owner,
        now: now,
      );

      final known = snapshot.rows.firstWhere((r) => r.memberUserId == 'known');
      final unknown =
          snapshot.rows.firstWhere((r) => r.memberUserId == 'unknownuserid123');
      expect(known.title, 'Ada Lovelace');
      expect(known.hasPartialMetadata, isFalse);
      // Bilinmeyen kullanıcı: kısaltılmış uid + kısmi metadata.
      expect(unknown.title, contains('…'));
      expect(unknown.hasPartialMetadata, isTrue);
    });

    test('self member is labelled and not moderatable', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: const [],
        members: [
          _member(userId: 'me', role: OfficeRole.owner),
        ],
        directory: const [],
        currentUid: 'me',
        actorRole: OfficeRole.owner,
        now: now,
      );
      final self = snapshot.rows.single;
      expect(self.title, 'Siz');
      expect(self.isSelf, isTrue);
      expect(self.canModerate, isFalse);
      expect(self.canSuspend, isFalse);
      expect(self.canRemove, isFalse);
    });

    test('manager can only remove consultants', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: const [],
        members: [
          _member(userId: 'c1', role: OfficeRole.consultant),
          _member(userId: 'm1', role: OfficeRole.manager),
        ],
        directory: const [],
        currentUid: 'actor',
        actorRole: OfficeRole.manager,
        now: now,
      );
      final consultant = snapshot.rows.firstWhere((r) => r.memberUserId == 'c1');
      final manager = snapshot.rows.firstWhere((r) => r.memberUserId == 'm1');
      expect(consultant.canRemove, isTrue);
      expect(manager.canRemove, isFalse);
    });

    test('empty state is honest about coverage', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: const [],
        members: const [],
        directory: const [],
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.coverageNote, contains('Henüz'));
    });

    test('coverage note flags onboarding is not server-tracked', () {
      final snapshot = computeUyeliklerSnapshot(
        invites: [_invite(id: 'i1')],
        members: [_member(userId: 'u1')],
        directory: const [],
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
      expect(snapshot.coverageNote.toLowerCase(), contains('onboarding'));
    });
  });

  group('uyelikler filter', () {
    late UyeliklerPageSnapshot snapshot;

    setUp(() {
      snapshot = computeUyeliklerSnapshot(
        invites: [
          _invite(
            id: 'i1',
            code: 'ALPHA111',
            usedCount: 0,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          _invite(
            id: 'i2',
            code: 'BETA2222',
            isActive: false,
            createdAt: now.subtract(const Duration(days: 30)),
          ),
        ],
        members: [
          _member(
            userId: 'u1',
            status: MembershipStatus.active,
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
          _member(
            userId: 'u2',
            status: MembershipStatus.suspended,
            joinedAt: now.subtract(const Duration(days: 40)),
          ),
        ],
        directory: const [],
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
    });

    test('search matches invite code', () {
      final out = filterUyeliklerRows(
        source: snapshot.rows,
        searchQuery: 'alpha',
        filter: UyeliklerFilter.all,
        now: now,
      );
      expect(out.length, 1);
      expect(out.first.inviteCode, 'ALPHA111');
    });

    test('pending filter returns only pending invites', () {
      final out = filterUyeliklerRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: UyeliklerFilter.pending,
        now: now,
      );
      expect(out.every((r) => r.durum == UyelikDurum.pending), isTrue);
      expect(out.length, 1);
    });

    test('intervention filter returns needsAction rows', () {
      final out = filterUyeliklerRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: UyeliklerFilter.intervention,
        now: now,
      );
      expect(out.every((r) => r.needsAction), isTrue);
      expect(out.length, 1);
    });

    test('members filter returns only memberships', () {
      final out = filterUyeliklerRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: UyeliklerFilter.members,
        now: now,
      );
      expect(out.every((r) => r.kind == UyelikKind.member), isTrue);
      expect(out.length, 2);
    });

    test('last7d filter excludes old records', () {
      final out = filterUyeliklerRows(
        source: snapshot.rows,
        searchQuery: '',
        filter: UyeliklerFilter.last7d,
        now: now,
      );
      // i1 (2h) ve u1 (1g) içeride; i2 (30g) ve u2 (40g) dışarıda.
      expect(out.length, 2);
    });
  });
}
