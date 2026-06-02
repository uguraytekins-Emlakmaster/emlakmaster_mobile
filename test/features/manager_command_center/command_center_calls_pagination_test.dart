import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_calls_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_query_document_snapshot.dart';

QueryDocumentSnapshot<Map<String, dynamic>> _doc(int i) =>
    fakeQueryDocumentSnapshot('c$i', {'createdAt': Timestamp.now()});

void main() {
  group('CommandCenterCallsAudience', () {
    test('hasContext: tüm ofisler ya da geçerli officeId', () {
      expect(
        const CommandCenterCallsAudience(allOffices: true, officeId: '')
            .hasContext,
        isTrue,
      );
      expect(
        const CommandCenterCallsAudience(allOffices: false, officeId: 'ofis1')
            .hasContext,
        isTrue,
      );
      expect(
        const CommandCenterCallsAudience(allOffices: false, officeId: '')
            .hasContext,
        isFalse,
      );
    });

    test('eşitlik & hashCode değer tabanlı', () {
      const a = CommandCenterCallsAudience(allOffices: false, officeId: 'o1');
      const b = CommandCenterCallsAudience(allOffices: false, officeId: 'o1');
      const c = CommandCenterCallsAudience(allOffices: true, officeId: 'o1');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('commandCenterCallsCanLoadMoreProvider', () {
    test('canlı pencere limitin altındaysa daha fazla yok', () {
      final container = ProviderContainer(
        overrides: [
          commandCenterCallsStreamProvider(CommandCenterCallsScope.all)
              .overrideWith(
            (ref) => Stream.value(
              fakeQuerySnapshot([_doc(1), _doc(2), _doc(3)]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      // İlk emit'i al.
      container.read(
        commandCenterCallsStreamProvider(CommandCenterCallsScope.all),
      );
      final canMore = container.read(
        commandCenterCallsCanLoadMoreProvider(CommandCenterCallsScope.all),
      );
      expect(canMore, isFalse);
    });

    test('canlı pencere limite ulaştıysa daha fazla yüklenebilir', () async {
      final docs = List.generate(
        FirestoreService.callsLiveStreamLimit,
        _doc,
      );
      final container = ProviderContainer(
        overrides: [
          commandCenterCallsStreamProvider(CommandCenterCallsScope.all)
              .overrideWith((ref) => Stream.value(fakeQuerySnapshot(docs))),
        ],
      );
      addTearDown(container.dispose);
      // Stream'in ilk değerini bekle.
      await container.read(
        commandCenterCallsStreamProvider(CommandCenterCallsScope.all).future,
      );
      final canMore = container.read(
        commandCenterCallsCanLoadMoreProvider(CommandCenterCallsScope.all),
      );
      expect(canMore, isTrue);
    });

    test('pending kapsamında sayfalama yok', () {
      final container = ProviderContainer(
        overrides: [
          commandCenterCallsStreamProvider(CommandCenterCallsScope.pending)
              .overrideWith(
            (ref) => Stream.value(
              fakeQuerySnapshot(
                List.generate(FirestoreService.callsLiveStreamLimit, _doc),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final canMore = container.read(
        commandCenterCallsCanLoadMoreProvider(CommandCenterCallsScope.pending),
      );
      expect(canMore, isFalse);
    });
  });
}
