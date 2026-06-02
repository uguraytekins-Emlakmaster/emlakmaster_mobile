import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_filter.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRaporlarSnapshot — RBAC yüzeyleri', () {
    test('broker tüm yönetici yüzeylerini görür', () {
      final snap = computeRaporlarSnapshot(role: AppRole.brokerOwner);
      final ids = snap.entries.map((e) => e.id).toSet();
      expect(ids, containsAll(<String>{
        'kadro',
        'ekip',
        'audit',
        'uyelik',
        'ofis',
        'baglanti',
        'komuta_merkezi',
        'komuta_odasi',
      }));
      expect(snap.summary.activeSurfaces, snap.entries.length);
      expect(snap.summary.auditLive, isTrue);
      expect(snap.isEmpty, isFalse);
    });

    test('agent yalnızca komuta merkezini görür (audit/üyelik yok)', () {
      final snap = computeRaporlarSnapshot(role: AppRole.agent);
      final ids = snap.entries.map((e) => e.id).toList();
      expect(ids, ['komuta_merkezi']);
      expect(snap.summary.auditLive, isFalse);
      expect(snap.isEmpty, isFalse);
    });

    test('guest için hiçbir yönetici rapor yüzeyi yok', () {
      final snap = computeRaporlarSnapshot(role: AppRole.guest);
      expect(snap.entries, isEmpty);
      expect(snap.isEmpty, isTrue);
    });
  });

  group('grounded sinyaller', () {
    test('ofis + bağlantı müdahalesi öne alınır ve sayılır', () {
      final snap = computeRaporlarSnapshot(
        role: AppRole.brokerOwner,
        signals: const RaporlarGroundedSignals(
          officeKnown: true,
          officeIntervention: 2,
          officePendingInvites: 3,
          connectionKnown: true,
          connectionIntervention: 1,
          connectionReady: 4,
          teamsCount: 5,
        ),
      );

      // İlk iki yüzey müdahale gerektiren olmalı (stabil öne alma).
      expect(snap.entries.take(2).every((e) => e.needsAction), isTrue);
      expect(snap.summary.interventionAreas, 2);

      final ofis = snap.entries.firstWhere((e) => e.id == 'ofis');
      expect(ofis.needsAction, isTrue);
      expect(ofis.attentionLabel, '2 müdahale');
      expect(ofis.readinessLabel, 'Müdahale gerekli');

      final baglanti = snap.entries.firstWhere((e) => e.id == 'baglanti');
      expect(baglanti.needsAction, isTrue);
      expect(baglanti.scope, contains('4 hazır'));

      final uyelik = snap.entries.firstWhere((e) => e.id == 'uyelik');
      expect(uyelik.scope, contains('3 bekleyen davet'));

      final ekip = snap.entries.firstWhere((e) => e.id == 'ekip');
      expect(ekip.scope, contains('5 ekip'));

      expect(snap.summary.pendingInvites, 3);
      expect(snap.summary.connectionIntervention, 1);
      expect(snap.summary.teamsCount, 5);
    });

    test('grounded veri yoksa sayımlar sessizce gizlenir (uydurma yok)', () {
      final snap = computeRaporlarSnapshot(role: AppRole.brokerOwner);
      expect(snap.summary.pendingInvites, isNull);
      expect(snap.summary.connectionIntervention, isNull);
      expect(snap.summary.teamsCount, isNull);
      expect(snap.summary.interventionAreas, 0);
      expect(snap.entries.every((e) => !e.needsAction), isTrue);
    });

    test('ekip kaydı 0 ise kurulum bekliyor durumu (müdahale değil)', () {
      final snap = computeRaporlarSnapshot(
        role: AppRole.brokerOwner,
        signals: const RaporlarGroundedSignals(teamsCount: 0),
      );
      final ekip = snap.entries.firstWhere((e) => e.id == 'ekip');
      expect(ekip.readinessLabel, 'Kurulum bekliyor');
      expect(ekip.needsAction, isFalse);
    });
  });

  group('filterRaporlarEntries', () {
    final snap = computeRaporlarSnapshot(
      role: AppRole.brokerOwner,
      signals: const RaporlarGroundedSignals(
        officeKnown: true,
        officeIntervention: 1,
        connectionKnown: true,
        connectionIntervention: 1,
      ),
    );

    test('müdahale filtresi yalnızca needsAction döndürür', () {
      final res = filterRaporlarEntries(
        snap.entries,
        query: '',
        filter: RaporlarFilter.intervention,
      );
      expect(res.isNotEmpty, isTrue);
      expect(res.every((e) => e.needsAction), isTrue);
    });

    test('hazır filtresi müdahale gerektirmeyenleri döndürür', () {
      final res = filterRaporlarEntries(
        snap.entries,
        query: '',
        filter: RaporlarFilter.ready,
      );
      expect(res.every((e) => !e.needsAction), isTrue);
    });

    test('kategori filtresi (audit)', () {
      final res = filterRaporlarEntries(
        snap.entries,
        query: '',
        filter: RaporlarFilter.audit,
      );
      expect(res.map((e) => e.id), ['audit']);
    });

    test('arama metni kapsamı ile eşleşir', () {
      final res = filterRaporlarEntries(
        snap.entries,
        query: 'bağlantı',
        filter: RaporlarFilter.all,
      );
      expect(res.any((e) => e.id == 'baglanti'), isTrue);
    });
  });
}
