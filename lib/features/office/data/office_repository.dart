import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/storage_upload_result.dart';
import '../domain/office_entity.dart';

class OfficeRepository {
  OfficeRepository._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String get _col => AppConstants.colOffices;

  /// Ofis logosu meta verisi (Storage yükleme sonrası).
  static Future<void> patchOfficeLogo({
    required String officeId,
    required StorageUploadResult upload,
    required String ownerUserId,
  }) async {
    await _db.collection(_col).doc(officeId).set(
      {
        'logoUrl': upload.downloadUrl,
        'logoStoragePath': upload.storagePath,
        'logoMimeType': upload.mimeType,
        'logoSizeBytes': upload.sizeBytes,
        'logoUploadedAt': FieldValue.serverTimestamp(),
        'logoOwnerUserId': ownerUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Logo alanlarını temizle (Storage silme ayrıca [OfficeLogoStorageService] ile).
  static Future<void> clearOfficeLogoFields(String officeId) async {
    await _db.collection(_col).doc(officeId).set(
      {
        'logoUrl': FieldValue.delete(),
        'logoStoragePath': FieldValue.delete(),
        'logoMimeType': FieldValue.delete(),
        'logoSizeBytes': FieldValue.delete(),
        'logoUploadedAt': FieldValue.delete(),
        'logoOwnerUserId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

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
