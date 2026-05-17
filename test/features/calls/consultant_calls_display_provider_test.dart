import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_display_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

void main() {
  test('consultantCallsDisplayProvider shows stale list while reloading',
      () async {
    final stale = [
      fakeQueryDocumentSnapshot('c1', {'createdAt': Timestamp.now()}),
    ];
    final container = ProviderContainer(
      overrides: [
        consultantCallsStaleCacheProvider.overrideWith(() {
          return _FixedStaleCache(stale);
        }),
        consultantCallsStreamProvider.overrideWith(
          (ref) => const Stream.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final display = container.read(consultantCallsDisplayProvider);
    expect(display.hasValue, isTrue);
    expect(display.value, hasLength(1));
    expect(display.value!.first.id, 'c1');
  });
}

class _FixedStaleCache extends ConsultantCallsStaleCache {
  _FixedStaleCache(this._value);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _value;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build() => _value;
}
