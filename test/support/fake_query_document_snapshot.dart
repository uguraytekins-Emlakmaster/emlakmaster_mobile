// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';

/// Test double — yalnızca [id] ve [data] gerekli senaryolar için.
QueryDocumentSnapshot<Map<String, dynamic>> fakeQueryDocumentSnapshot(
  String id,
  Map<String, dynamic> data,
) =>
    _FakeQueryDocumentSnapshot(id, data);

/// Test double — yalnızca [docs] gereken senaryolar için sahte QuerySnapshot.
QuerySnapshot<Map<String, dynamic>> fakeQuerySnapshot(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) =>
    _FakeQuerySnapshot(docs);

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => const [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => docs.length;
}

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
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
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();
}
