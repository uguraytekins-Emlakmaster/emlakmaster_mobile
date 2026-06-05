import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('permission-denied maps to user-safe Turkish message', () {
    final msg = userFacingFirebaseMessage(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'The caller does not have permission',
      ),
    );
    expect(msg, contains('yetkiniz'));
    expect(msg, isNot(contains('permission-denied')));
  });
}
