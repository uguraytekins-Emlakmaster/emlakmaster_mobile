import 'package:emlakmaster_mobile/core/services/auth_firestore_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFirestoreGate', () {
    test('liveUidMatches returns false for empty uid', () {
      expect(AuthFirestoreGate.liveUidMatches(''), isFalse);
    });
  });
}
