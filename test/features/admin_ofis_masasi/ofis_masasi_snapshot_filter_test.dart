// ignore_for_file: avoid_redundant_argument_values

import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_filter.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_connection_mode.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_setup_status.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_record.dart';
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

PlatformSetupRecord _setup(
  IntegrationPlatformId pid, {
  bool oauthVerified = false,
  IntegrationSetupStatus setupStatus = IntegrationSetupStatus.inProgress,
  String? storeName,
}) {
  final now = DateTime(2026, 5, 30);
  return PlatformSetupRecord(
    platform: pid,
    officeId: 'o1',
    ownerUserId: 'admin1',
    connectionMode: IntegrationConnectionMode.fileImport,
    setupStatus: setupStatus,
    storeName: storeName,
    oauthVerified: oauthVerified,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final now = DateTime(2026, 5, 31, 12, 0);

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('ofis masasi snapshot — members & invites', () {
    test('separates members/invites and sorts intervention first', () {
      final snapshot = computeOfisMasasiSnapshot(
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
        setups: const {},
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );

      expect(snapshot.members.length, 2);
      expect(snapshot.invites.length, 1);
      // Askıdaki üye ilk sırada.
      expect(snapshot.members.first.needsAction, isTrue);
      expect(snapshot.isEmpty, isFalse);
    });

    test('summary counts only grounded values', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: [
          _invite(id: 'i1', usedCount: 0), // bekleyen
          _invite(
            id: 'i2',
            expiresAt: now.subtract(const Duration(days: 1)),
          ), // süresi dolan → müdahale
        ],
        members: [
          _member(userId: 'u1', status: MembershipStatus.active),
          _member(userId: 'u2', status: MembershipStatus.suspended),
        ],
        directory: const [],
        setups: const {},
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );

      expect(snapshot.summary.pendingInvites, 1);
      expect(snapshot.summary.activeMembers, 1);
      expect(snapshot.summary.suspendedMembers, 1);
      // 1 askıda üye + 1 süresi dolan davet (bağlantı yok → 0).
      expect(snapshot.summary.interventionCount, 2);
    });

    test('resolves member name from directory, honest fallback otherwise', () {
      final snapshot = computeOfisMasasiSnapshot(
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
        setups: const {},
        currentUid: 'me',
        actorRole: OfficeRole.owner,
        now: now,
      );

      final known =
          snapshot.members.firstWhere((r) => r.memberUserId == 'known');
      final unknown = snapshot.members
          .firstWhere((r) => r.memberUserId == 'unknownuserid123');
      expect(known.title, 'Ada Lovelace');
      expect(known.hasPartialMetadata, isFalse);
      expect(unknown.title, contains('…'));
      expect(unknown.hasPartialMetadata, isTrue);
    });

    test('manager can only remove consultants', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: const [],
        members: [
          _member(userId: 'c1', role: OfficeRole.consultant),
          _member(userId: 'm1', role: OfficeRole.manager),
        ],
        directory: const [],
        setups: const {},
        currentUid: 'actor',
        actorRole: OfficeRole.manager,
        now: now,
      );
      final consultant =
          snapshot.members.firstWhere((r) => r.memberUserId == 'c1');
      final manager =
          snapshot.members.firstWhere((r) => r.memberUserId == 'm1');
      expect(consultant.canRemove, isTrue);
      expect(manager.canRemove, isFalse);
    });

    test('self member is labelled and not moderatable', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: const [],
        members: [_member(userId: 'me', role: OfficeRole.owner)],
        directory: const [],
        setups: const {},
        currentUid: 'me',
        actorRole: OfficeRole.owner,
        now: now,
      );
      final self = snapshot.members.single;
      expect(self.title, 'Siz');
      expect(self.isSelf, isTrue);
      expect(self.canSuspend, isFalse);
      expect(self.canRemove, isFalse);
    });
  });

  group('ofis masasi snapshot — connections (real platform_setups)', () {
    test('builds one row per catalog platform with honest lifecycle', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: const [],
        members: const [],
        directory: const [],
        setups: {
          IntegrationPlatformId.sahibinden:
              _setup(IntegrationPlatformId.sahibinden, oauthVerified: true),
          IntegrationPlatformId.hepsiemlak: _setup(
            IntegrationPlatformId.hepsiemlak,
            setupStatus: IntegrationSetupStatus.error,
          ),
          // emlakjet: kurulum kaydı yok → notStarted.
        },
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );

      expect(snapshot.connectionsKnown, isTrue);
      expect(snapshot.connections.length, IntegrationPlatformId.values.length);
      expect(snapshot.summary.connectionsReady, 1); // sahibinden (liveEnabled)
      expect(snapshot.summary.connectionsNeedingSetup, 2);
      // error bağlantı müdahale sayılır.
      expect(snapshot.summary.interventionCount, greaterThanOrEqualTo(1));

      final emlakjet = snapshot.connections
          .firstWhere((r) => r.connectionPlatformKey == 'emlakjet');
      expect(emlakjet.connectionConfigured, isFalse);
      expect(emlakjet.hasPartialMetadata, isTrue);
    });

    test('null setups → connections unknown, metrics hidden honestly', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: const [],
        members: [_member(userId: 'u1')],
        directory: const [],
        setups: null,
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
      expect(snapshot.connectionsKnown, isFalse);
      expect(snapshot.connections, isEmpty);
      expect(snapshot.summary.connectionsKnown, isFalse);
      expect(snapshot.summary.totalConnections, 0);
    });
  });

  group('ofis masasi coverage note (honesty)', () {
    test('empty office is honest about coverage', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: const [],
        members: const [],
        directory: const [],
        setups: const {},
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.coverageNote, contains('Henüz'));
    });

    test('coverage note flags no fake live sync / onboarding', () {
      final snapshot = computeOfisMasasiSnapshot(
        invites: [_invite(id: 'i1')],
        members: [_member(userId: 'u1')],
        directory: const [],
        setups: const {},
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
      expect(snapshot.coverageNote.toLowerCase(), contains('onboarding'));
      expect(snapshot.coverageNote.toLowerCase(), contains('canlı senkron'));
    });
  });

  group('ofis masasi filter', () {
    late OfisMasasiSnapshot snapshot;

    setUp(() {
      snapshot = computeOfisMasasiSnapshot(
        invites: [
          _invite(
            id: 'i1',
            code: 'ALPHA111',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        members: [
          _member(
            userId: 'u1',
            status: MembershipStatus.active,
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        directory: [_user('u1', name: 'Zeynep Kaya')],
        setups: {
          IntegrationPlatformId.sahibinden:
              _setup(IntegrationPlatformId.sahibinden, oauthVerified: true),
        },
        currentUid: null,
        actorRole: OfficeRole.owner,
        now: now,
      );
    });

    test('empty query returns source unchanged', () {
      final out =
          filterOfisMasasiRows(source: snapshot.allRows, query: '   ');
      expect(out.length, snapshot.allRows.length);
    });

    test('search matches invite code', () {
      final out =
          filterOfisMasasiRows(source: snapshot.allRows, query: 'alpha');
      expect(out.length, 1);
      expect(out.first.inviteCode, 'ALPHA111');
    });

    test('search matches member name', () {
      final out =
          filterOfisMasasiRows(source: snapshot.members, query: 'zeynep');
      expect(out.length, 1);
      expect(out.first.title, 'Zeynep Kaya');
    });

    test('search matches connection platform name', () {
      final out = filterOfisMasasiRows(
        source: snapshot.connections,
        query: 'sahibinden',
      );
      expect(out.length, 1);
      expect(out.first.connectionPlatformKey, 'sahibinden');
    });
  });
}
