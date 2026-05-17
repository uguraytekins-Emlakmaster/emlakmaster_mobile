import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_calls_display_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

void main() {
  test(
    'commandCenterCallsDisplayProvider shows stale list while reloading',
    () {
      final stale = [
        fakeQueryDocumentSnapshot('cc1', {'createdAt': Timestamp.now()}),
      ];
      final container = ProviderContainer(
        overrides: [
          commandCenterCallsStaleCacheProvider.overrideWith(
            () => _FixedCommandCenterStaleCache(stale),
          ),
          commandCenterCallsStreamProvider(CommandCenterCallsScope.all)
              .overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      final display = container.read(
        commandCenterCallsDisplayProvider(CommandCenterCallsScope.all),
      );
      expect(display.hasValue, isTrue);
      expect(display.value, hasLength(1));
      expect(display.value!.first.id, 'cc1');
    },
  );
}

class _FixedCommandCenterStaleCache extends CommandCenterCallsStaleCache {
  _FixedCommandCenterStaleCache(this._value);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _value;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? build(
    CommandCenterCallsScope scope,
  ) =>
      _value;
}
