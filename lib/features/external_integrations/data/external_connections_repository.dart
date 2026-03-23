import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';

import '../domain/external_connection_entity.dart';

/// Kullanıcının harici hesap bağlantıları.
class ExternalConnectionsRepository {
  ExternalConnectionsRepository._();
  static final ExternalConnectionsRepository instance = ExternalConnectionsRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(AppConstants.colExternalConnections);

  /// `userId` alanına göre sorgu (tek alan — basit index / varsayılan kurallar).
  Stream<List<ExternalConnectionEntity>> streamForUser(String userId) {
    return _col.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs.map(ExternalConnectionEntity.fromDoc).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }
}
