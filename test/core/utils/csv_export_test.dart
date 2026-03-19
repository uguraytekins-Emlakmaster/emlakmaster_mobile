// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock doc for CSV export tests (QueryDocumentSnapshot only needs id + data()).
QueryDocumentSnapshot<Map<String, dynamic>> _mockDoc(
  String id,
  Map<String, dynamic> data,
) {
  return _FakeQueryDocumentSnapshot(id, data);
}

class _FakeQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this.id, this._data);
  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(_data);

  @override
  Object? get(Object field) => _data[field];

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();
}

void main() {
  group('callsToCsvWithPhones', () {
    test('empty list returns header only with BOM', () {
      final csv = callsToCsvWithPhones([]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('id,tarih,yon,telefon,sure_sn,sonuc,createdAt'), isTrue);
    });

    test('one doc with phone and direction produces one data row', () {
      final createdAt = DateTime(2024, 3, 15, 14, 30);
      final docs = [
        _mockDoc('doc1', {
          'direction': 'incoming',
          'phoneNumber': '5551234567',
          'durationSec': 120,
          'outcome': 'connected',
          'createdAt': Timestamp.fromDate(createdAt),
        }),
      ];
      final csv = callsToCsvWithPhones(docs);
      expect(csv.contains('doc1'), isTrue);
      expect(csv.contains('incoming'), isTrue);
      expect(csv.contains('5551234567'), isTrue);
      expect(csv.contains('120'), isTrue);
      expect(csv.contains('connected'), isTrue);
    });
  });

  group('callsToCsv', () {
    test('empty list returns header with BOM', () {
      final csv = callsToCsv([]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('id,agentId,durationSec,outcome,createdAt'), isTrue);
    });
  });
}
