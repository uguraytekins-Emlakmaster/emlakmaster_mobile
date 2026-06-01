import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2024, 6, 15, 12);

ResurrectionQueueItem _item({
  required String id,
  ResurrectionSegment? segment,
  int days = 7,
  String? phone,
  String? name,
  CustomerHeatLevel? heat,
  String? nextAction,
  String? callSummary,
}) {
  return ResurrectionQueueItem(
    customerId: id,
    customerName: name ?? 'Müşteri $id',
    primaryPhone: phone,
    segment: segment,
    daysSilent: days,
    heatLevel: heat,
    nextSuggestedAction: nextAction,
    lastCallSummary: callSummary,
  );
}

void main() {
  group('computeFollowUpWorkspaceSnapshot', () {
    test('summary gerçek sayımlar', () {
      final snap = computeFollowUpWorkspaceSnapshot(
        [
          _item(
            id: 'today',
            segment: ResurrectionSegment.silent7,
            days: 7,
            phone: '+905551111111',
          ),
          _item(
            id: 'over',
            segment: ResurrectionSegment.silent14,
            days: 14,
          ),
          _item(
            id: 'hot',
            segment: ResurrectionSegment.silent30,
            days: 30,
            heat: CustomerHeatLevel.hot,
          ),
        ],
        now: _now,
      );
      expect(snap.summary.active, 3);
      expect(snap.summary.overdue, greaterThanOrEqualTo(1));
      expect(snap.summary.today, 1);
      expect(snap.summary.matched, 3);
    });

    test('geciken üst sıralama', () {
      final snap = computeFollowUpWorkspaceSnapshot(
        [
          _item(id: 'later', segment: ResurrectionSegment.silent7, days: 7),
          _item(id: 'over', segment: ResurrectionSegment.silent30, days: 30),
        ],
        now: _now,
      );
      expect(snap.rows.first.customerId, 'over');
    });

    test('coverageNote dürüst — AI yok', () {
      final snap = computeFollowUpWorkspaceSnapshot(
        [_item(id: 'a')],
        now: _now,
      );
      expect(snap.coverageNote, contains('AI'));
      expect(snap.coverageNote, contains('tamamlandı'));
    });

    test('kısmi — telefon ve bağlam eksik', () {
      final snap = computeFollowUpWorkspaceSnapshot(
        [
          _item(
            id: 'partial',
            phone: null,
            nextAction: null,
            callSummary: null,
          ),
        ],
        now: _now,
      );
      expect(snap.rows.single.isPartial, isTrue);
      expect(snap.summary.partial, 1);
    });

    test('hızlı çözülebilir — 7 gün + aranabilir telefon', () {
      final snap = computeFollowUpWorkspaceSnapshot(
        [
          _item(
            id: 'quick',
            segment: ResurrectionSegment.silent7,
            days: 7,
            phone: '+905559999999',
          ),
        ],
        now: _now,
      );
      expect(snap.quickCloseRows, isNotEmpty);
      expect(snap.quickCloseRows.first.quickResolvable, isTrue);
    });
  });

  group('filterFollowUpWorkspaceRows', () {
    late List<FollowUpRowView> rows;

    setUp(() {
      rows = computeFollowUpWorkspaceSnapshot(
        [
          _item(
            id: 'over',
            segment: ResurrectionSegment.silent14,
            days: 14,
          ),
          _item(
            id: 'today',
            segment: ResurrectionSegment.silent7,
            days: 7,
            phone: '+905551111111',
          ),
          _item(
            id: 'hot',
            segment: ResurrectionSegment.silent30,
            days: 30,
            heat: CustomerHeatLevel.hot,
          ),
        ],
        now: _now,
      ).rows;
    });

    test('geciken filtresi', () {
      final out = filterFollowUpWorkspaceRows(
        rows,
        filter: FollowUpWorkspaceFilter.overdue,
      );
      expect(out.every((r) => r.isOverdue), isTrue);
    });

    test('arama metni', () {
      final out = filterFollowUpWorkspaceRows(rows, query: 'müşteri today');
      expect(out.any((r) => r.customerId == 'today'), isTrue);
    });

    test('öncelikli', () {
      final out = filterFollowUpWorkspaceRows(
        rows,
        filter: FollowUpWorkspaceFilter.priority,
      );
      expect(out, isNotEmpty);
      expect(out.every((r) => r.isPriority), isTrue);
    });
  });
}
