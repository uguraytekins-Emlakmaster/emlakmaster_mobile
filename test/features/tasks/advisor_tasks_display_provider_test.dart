import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_display_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

void main() {
  test('advisorTasksDisplayProvider shows stale list while reloading', () {
    final stale = [
      fakeQueryDocumentSnapshot('t1', {'title': 'Ara'}),
    ];
    const uid = 'advisor-1';
    final container = ProviderContainer(
      overrides: [
        advisorTasksStaleCacheProvider.overrideWith(
          () => _FixedTasksStaleCache(stale),
        ),
        advisorTasksStreamProvider(uid).overrideWith(
          (ref) => const Stream.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final display = container.read(advisorTasksDisplayProvider(uid));
    expect(display.hasValue, isTrue);
    expect(display.value, hasLength(1));
    expect(display.value!.first.id, 't1');
  });
}

class _FixedTasksStaleCache extends AdvisorTasksStaleCache {
  _FixedTasksStaleCache(this._value);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _value;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String uid) =>
      _value;
}
