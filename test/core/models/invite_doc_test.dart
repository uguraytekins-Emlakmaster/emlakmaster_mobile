import 'package:emlakmaster_mobile/core/models/invite_doc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteDoc', () {
    test('fromFirestore with null data returns null', () {
      expect(InviteDoc.fromFirestore('id1', null), isNull);
    });

    test('fromFirestore with empty email returns null', () {
      expect(
        InviteDoc.fromFirestore('id1', {'email': '', 'role': 'agent', 'createdBy': 'uid'}),
        isNull,
      );
    });

    test('fromFirestore with valid data returns InviteDoc', () {
      final doc = InviteDoc.fromFirestore('inv-1', {
        'email': 'test@example.com',
        'role': 'agent',
        'createdBy': 'creator-uid',
        'teamId': 'team-1',
        'name': 'Test User',
      });
      expect(doc, isNotNull);
      expect(doc!.id, 'inv-1');
      expect(doc.email, 'test@example.com');
      expect(doc.role, 'agent');
      expect(doc.createdBy, 'creator-uid');
      expect(doc.teamId, 'team-1');
      expect(doc.name, 'Test User');
    });

    test('fromFirestore with minimal fields uses defaults', () {
      final doc = InviteDoc.fromFirestore('inv-2', {
        'email': 'min@test.com',
        'createdBy': 'uid',
      });
      expect(doc, isNotNull);
      expect(doc!.role, 'agent');
      expect(doc.teamId, isNull);
      expect(doc.name, isNull);
    });
  });
}
