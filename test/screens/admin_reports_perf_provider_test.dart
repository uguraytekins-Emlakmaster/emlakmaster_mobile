import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/screens/providers/admin_reports_perf_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_query_document_snapshot.dart';

void main() {
  test('adminReportsPerfProvider merges summaries and deals', () async {
    final container = ProviderContainer(
      overrides: [
        adminCallSummariesSampleProvider.overrideWith(
          (ref) => Stream.value(
            _FakeSnapshot([fakeQueryDocumentSnapshot('s1', {})]),
          ),
        ),
        adminDealsSampleProvider.overrideWith(
          (ref) => Stream.value(_FakeSnapshot([])),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(adminCallSummariesSampleProvider.future);
    await container.read(adminDealsSampleProvider.future);

    final perf = container.read(adminReportsPerfProvider);
    expect(perf.hasValue, isTrue);
    expect(perf.value!.hasSummaries, isTrue);
    expect(perf.value!.hasDeals, isFalse);
    expect(perf.value!.hasAnyData, isTrue);
  });
}

class _FakeSnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeSnapshot(this._docs);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
