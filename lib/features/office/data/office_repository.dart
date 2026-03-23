import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/office_entity.dart';

class OfficeRepository {
  OfficeRepository._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String get _col => AppConstants.colOffices;

  static Stream<Office?> watchOffice(String officeId) {
    return _db.collection(_col).doc(officeId).snapshots().map((s) {
      if (!s.exists) return null;
      return Office.fromFirestore(s.id, s.data());
    });
  }

  static Future<Office?> getOffice(String officeId) async {
    try {
      final s = await _db.collection(_col).doc(officeId).get();
      if (!s.exists) return null;
      return Office.fromFirestore(s.id, s.data());
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeRepository.getOffice', e, st);
      rethrow;
    }
  }
}
