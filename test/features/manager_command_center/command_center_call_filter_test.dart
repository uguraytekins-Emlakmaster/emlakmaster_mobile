import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_feed_filters.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_view_scope.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/utils/command_center_call_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

void main() {
  test('filterCommandCenterCalls respects agent and phone search', () {
    final docs = [
      fakeQueryDocumentSnapshot('c1', {
        'agentId': 'a1',
        'phoneNumber': '+905551112233',
        'outcome': 'answered',
      }),
      fakeQueryDocumentSnapshot('c2', {
        'agentId': 'a2',
        'phoneNumber': '+905559998877',
        'outcome': 'missed',
      }),
    ];
    final filters = CommandCenterFeedFilters(
      viewScope: CommandCenterViewScope.all,
      searchQueryLower: '1122',
      filterAgentId: 'a1',
      quickFilter: CallSurfaceQuickFilter.all,
    );
    final filtered = filterCommandCenterCalls(
      docs: docs,
      filters: filters,
      customerFullNameById: const {},
    );
    expect(filtered, hasLength(1));
    expect(filtered.first.id, 'c1');
  });

  test('filterCommandCenterCalls resolves customer name in search', () {
    final docs = [
      fakeQueryDocumentSnapshot('c1', {
        'agentId': 'a1',
        'customerId': 'cust-1',
        'phoneNumber': '+905551110000',
      }),
    ];
    final filters = CommandCenterFeedFilters(
      viewScope: CommandCenterViewScope.all,
      searchQueryLower: 'ayşe',
      quickFilter: CallSurfaceQuickFilter.all,
    );
    final filtered = filterCommandCenterCalls(
      docs: docs,
      filters: filters,
      customerFullNameById: const {'cust-1': 'Ayşe Yılmaz'},
    );
    expect(filtered, hasLength(1));
  });
}
