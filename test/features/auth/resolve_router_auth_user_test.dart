import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [User] stub for router auth resolution tests.
class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('resolveRouterAuthUser', () {
    test('prefers live Firebase user when signed in', () {
      final streamUser = _FakeUser('stream');
      final liveUser = _FakeUser('live');
      expect(
        resolveRouterAuthUser(
          streamUser: streamUser,
          liveFirebaseUser: liveUser,
          firebaseReady: true,
        ),
        same(liveUser),
      );
    });

    test('returns null on sign-out even if stream still has stale user', () {
      final staleUser = _FakeUser('stale');
      expect(
        resolveRouterAuthUser(
          streamUser: staleUser,
          liveFirebaseUser: null,
          firebaseReady: true,
        ),
        isNull,
      );
    });

    test('uses stream when Firebase not ready yet', () {
      final streamUser = _FakeUser('bootstrap');
      expect(
        resolveRouterAuthUser(
          streamUser: streamUser,
          liveFirebaseUser: null,
          firebaseReady: false,
        ),
        same(streamUser),
      );
    });

    test('returns null when signed out and stream also null', () {
      expect(
        resolveRouterAuthUser(
          streamUser: null,
          liveFirebaseUser: null,
          firebaseReady: true,
        ),
        isNull,
      );
    });
  });
}
