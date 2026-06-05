import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';
import 'package:flutter_test/flutter_test.dart';

ResurrectionQueueItem _item({
  required String id,
  ResurrectionSegment? segment,
  int days = 7,
  String? phone,
  CustomerHeatLevel? heat,
  String? nextAction,
}) {
  return ResurrectionQueueItem(
    customerId: id,
    customerName: 'Müşteri $id',
    primaryPhone: phone,
    segment: segment,
    daysSilent: days,
    heatLevel: heat,
    heatScore: heat != null ? 50 : null,
    nextSuggestedAction: nextAction,
  );
}

void main() {
  group('computeFollowUpListSummary', () {
    test('counts real segments and fields', () {
      final items = [
        _item(
          id: 'a',
          segment: ResurrectionSegment.silent7,
          days: 7,
          phone: '+905551111111',
        ),
        _item(
          id: 'b',
          segment: ResurrectionSegment.silent14,
          days: 14,
          heat: CustomerHeatLevel.cold,
        ),
        _item(
          id: 'c',
          segment: ResurrectionSegment.silent30,
          days: 30,
          nextAction: 'Fiyat görüşmesi',
          heat: CustomerHeatLevel.hot,
        ),
      ];
      final s = computeFollowUpListSummary(items);
      expect(s.todayFollowUp, 1);
      expect(s.overdue, 2);
      expect(s.callback, 1);
      expect(s.coldLeads, 1);
      expect(s.opportunity, 1);
    });
  });

  group('matchesFollowUpListFilter', () {
    test('search matches name and phone', () {
      final row = _item(id: 'x', phone: '+905559999999');
      expect(
        matchesFollowUpListFilter(row, FollowUpListFilter.all, 'müşteri'),
        isTrue,
      );
      expect(
        matchesFollowUpListFilter(row, FollowUpListFilter.all, '9999'),
        isTrue,
      );
      expect(
        matchesFollowUpListFilter(row, FollowUpListFilter.all, 'yok'),
        isFalse,
      );
    });

    test('filter chips use honest rules', () {
      final today = _item(
        id: 't',
        segment: ResurrectionSegment.silent7,
        days: 7,
      );
      final overdue = _item(
        id: 'o',
        segment: ResurrectionSegment.silent30,
        days: 30,
      );
      final hot = _item(
        id: 'h',
        segment: ResurrectionSegment.silent14,
        days: 14,
        heat: CustomerHeatLevel.hot,
      );
      final opp = _item(
        id: 'f',
        segment: ResurrectionSegment.silent14,
        days: 14,
        nextAction: 'Randevu',
      );

      expect(
        matchesFollowUpListFilter(today, FollowUpListFilter.today, ''),
        isTrue,
      );
      expect(
        matchesFollowUpListFilter(overdue, FollowUpListFilter.overdue, ''),
        isTrue,
      );
      expect(
        matchesFollowUpListFilter(hot, FollowUpListFilter.hot, ''),
        isTrue,
      );
      expect(
        matchesFollowUpListFilter(opp, FollowUpListFilter.opportunity, ''),
        isTrue,
      );
    });
  });
}
