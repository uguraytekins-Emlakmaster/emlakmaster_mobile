import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2024, 6, 15, 12);

CallWorkspaceInput _input({
  String recordKey = 'fs_1',
  String sourceKind = 'firestore',
  String? firestoreDocId = 'doc1',
  String rawPhone = '+905321112233',
  String? customerId,
  String? customerFullName,
  String? contactDisplayName,
  bool isIncoming = false,
  int? durationSec = 120,
  String? outcomeCode = 'reached',
  String outcomeLabel = 'Ulaşıldı',
  DateTime? createdAt,
  bool isHandoffPending = false,
  bool hasCaptureCompleted = true,
  bool isLocalDraft = false,
  String? notes,
}) =>
    CallWorkspaceInput(
      recordKey: recordKey,
      sourceKind: sourceKind,
      firestoreDocId: firestoreDocId,
      rawPhone: rawPhone,
      customerId: customerId,
      customerFullName: customerFullName,
      contactDisplayName: contactDisplayName,
      isIncoming: isIncoming,
      durationSec: durationSec,
      outcomeCode: outcomeCode,
      outcomeLabel: outcomeLabel,
      createdAt: createdAt ?? _now.subtract(const Duration(hours: 2)),
      isHandoffPending: isHandoffPending,
      hasCaptureCompleted: hasCaptureCompleted,
      isLocalDraft: isLocalDraft,
      notes: notes,
    );

CallRowView _rowByKey(CallsWorkspaceSnapshot s, String key) =>
    s.rows.firstWhere((r) => r.recordKey == key);

void main() {
  group('computeCallsWorkspaceSnapshot — gerçek çağrı sinyalleri', () {
    test('summary yalnızca gerçek sayımları döndürür', () {
      final snap = computeCallsWorkspaceSnapshot(
        [
          _input(recordKey: 'today', createdAt: _now),
          _input(
            recordKey: 'cb',
            createdAt: _now.subtract(const Duration(days: 1)),
            outcomeCode: 'callback_scheduled',
            outcomeLabel: 'Tekrar aranacak',
          ),
          _input(
            recordKey: 'match',
            createdAt: _now.subtract(const Duration(days: 2)),
            customerId: 'c1',
            customerFullName: 'Ada',
          ),
          _input(
            recordKey: 'partial',
            createdAt: _now.subtract(const Duration(days: 3)),
            customerId: null,
            contactDisplayName: null,
            outcomeCode: '',
            outcomeLabel: '—',
          ),
          _input(
            recordKey: 'miss',
            createdAt: _now.subtract(const Duration(days: 4)),
            outcomeCode: 'missed',
            outcomeLabel: 'Cevapsız',
          ),
        ],
        now: _now,
      );
      expect(snap.summary.today, 1);
      expect(snap.summary.callback, greaterThanOrEqualTo(1));
      expect(snap.summary.matched, 1);
      expect(snap.summary.partial, greaterThanOrEqualTo(1));
      expect(snap.summary.unanswered, 1);
    });

    test('coverageNote dürüst — uydurma KPI yok', () {
      final snap = computeCallsWorkspaceSnapshot([_input()], now: _now);
      expect(snap.coverageNote, contains('iOS'));
      expect(snap.coverageNote, contains('uydurma KPI'));
    });

    test('cevapsız yalnızca grounded outcome kodları', () {
      final snap = computeCallsWorkspaceSnapshot(
        [
          _input(
            recordKey: 'miss',
            outcomeCode: 'missed',
            outcomeLabel: 'Cevapsız',
          ),
          _input(recordKey: 'ok', outcomeCode: 'reached'),
        ],
        now: _now,
      );
      expect(_rowByKey(snap, 'miss').isUnanswered, isTrue);
      expect(_rowByKey(snap, 'ok').isUnanswered, isFalse);
    });

    test('geri dön lane gerçek callback/bekleyen kayıtlar', () {
      final snap = computeCallsWorkspaceSnapshot(
        [
          _input(
            recordKey: 'cb',
            outcomeCode: 'callback_scheduled',
            outcomeLabel: 'Tekrar aranacak',
          ),
          _input(recordKey: 'done', outcomeCode: 'reached'),
        ],
        now: _now,
      );
      expect(snap.attentionRows.length, 1);
      expect(snap.attentionRows.first.recordKey, 'cb');
    });

    test('tarih sıralaması — en yeni çağrı üstte', () {
      final snap = computeCallsWorkspaceSnapshot(
        [
          _input(
            recordKey: 'older',
            createdAt: _now.subtract(const Duration(days: 3)),
          ),
          _input(recordKey: 'newest', createdAt: _now),
          _input(
            recordKey: 'mid',
            createdAt: _now.subtract(const Duration(days: 1)),
          ),
        ],
        now: _now,
      );
      expect(
        snap.rows.map((r) => r.recordKey).toList(),
        ['newest', 'mid', 'older'],
      );
    });

    test('callback şeridi aciliyet önceliğini korur', () {
      final snap = computeCallsWorkspaceSnapshot(
        [
          _input(recordKey: 'recent_reached', createdAt: _now),
          _input(
            recordKey: 'old_cb',
            createdAt: _now.subtract(const Duration(days: 2)),
            outcomeCode: 'callback_scheduled',
            outcomeLabel: 'Tekrar aranacak',
          ),
          _input(
            recordKey: 'old_miss_cb',
            createdAt: _now.subtract(const Duration(days: 3)),
            outcomeCode: 'missed',
            outcomeLabel: 'Cevapsız',
            hasCaptureCompleted: false,
          ),
        ],
        now: _now,
      );
      // Ana liste kronolojik: en yeni çağrı üstte.
      expect(snap.rows.first.recordKey, 'recent_reached');
      // Şerit aciliyet sırası: callback + cevapsız (rank 0) en üstte.
      expect(snap.attentionRows.first.recordKey, 'old_miss_cb');
    });

    test('dateChip bugün kayıt varsa gösterilir', () {
      final snap = computeCallsWorkspaceSnapshot(
        [_input(createdAt: _now)],
        now: _now,
      );
      expect(snap.dateChipLabel, '15.06.2024');
    });
  });

  group('filterCallsWorkspaceRows', () {
    late CallsWorkspaceSnapshot snap;

    setUp(() {
      snap = computeCallsWorkspaceSnapshot(
        [
          _input(recordKey: 'today', createdAt: _now, isIncoming: true),
          _input(
            recordKey: 'out',
            createdAt: _now.subtract(const Duration(days: 1)),
            isIncoming: false,
            customerId: 'c1',
            customerFullName: 'Ada',
          ),
          _input(
            recordKey: 'miss',
            createdAt: _now.subtract(const Duration(days: 2)),
            outcomeCode: 'missed',
            outcomeLabel: 'Cevapsız',
          ),
        ],
        now: _now,
      );
    });

    test('bugün filtresi', () {
      final out = filterCallsWorkspaceRows(
        snap.rows,
        filter: CallsWorkspaceFilter.today,
      );
      expect(out.map((r) => r.recordKey).toList(), ['today']);
    });

    test('gelen/giden filtresi', () {
      expect(
        filterCallsWorkspaceRows(
          snap.rows,
          filter: CallsWorkspaceFilter.incoming,
        ).length,
        1,
      );
      expect(
        filterCallsWorkspaceRows(
          snap.rows,
          filter: CallsWorkspaceFilter.outgoing,
        ).length,
        2,
      );
    });

    test('eşleşen filtresi', () {
      final out = filterCallsWorkspaceRows(
        snap.rows,
        filter: CallsWorkspaceFilter.matched,
      );
      expect(out.single.recordKey, 'out');
    });

    test('arama searchText üzerinde', () {
      final out = filterCallsWorkspaceRows(snap.rows, query: 'ada');
      expect(out.single.recordKey, 'out');
    });
  });
}
