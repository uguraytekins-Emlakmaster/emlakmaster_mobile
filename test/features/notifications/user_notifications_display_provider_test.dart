import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/notifications/presentation/providers/user_notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

void main() {
  test('userNotificationsDisplayProvider shows stale while reloading', () {
    const uid = 'u1';
    final stale = [
      fakeQueryDocumentSnapshot('n1', {'title': 'Test'}),
    ];
    final container = ProviderContainer(
      overrides: [
        userNotificationsStaleCacheProvider.overrideWith(
          () => _FixedNotificationsStale(stale),
        ),
        userNotificationsStreamProvider(uid).overrideWith(
          (ref) => const Stream.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final display = container.read(userNotificationsDisplayProvider(uid));
    expect(display.hasValue, isTrue);
    expect(display.value, hasLength(1));
  });
}

class _FixedNotificationsStale extends UserNotificationsStaleCache {
  _FixedNotificationsStale(this._value);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _value;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(String uid) =>
      _value;
}
