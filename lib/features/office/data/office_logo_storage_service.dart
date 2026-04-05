import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/storage/storage_paths.dart';
import 'package:emlakmaster_mobile/core/storage/storage_upload_result.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Ofis logosu: `offices/{officeId}/logo/{fileName}` — yazma kuralları Storage + Firestore ile hizalı.
class OfficeLogoStorageService {
  OfficeLogoStorageService._();
  static final OfficeLogoStorageService instance = OfficeLogoStorageService._();

  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<StorageUploadResult?> uploadOfficeLogoBytes({
    required String officeId,
    required Uint8List bytes,
    String? previousStoragePath,
  }) async {
    if (!await FirebaseStorageAvailability.checkUsable()) return null;
    try {
      if (previousStoragePath != null && previousStoragePath.isNotEmpty) {
        await _storage.ref(previousStoragePath).delete().catchError((_) {});
      }
      final fileName = 'office_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = StoragePaths.officeLogo(officeId, fileName);
      final ref = _storage.ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=86400',
        ),
      );
      final url = await ref.getDownloadURL();
      return StorageUploadResult(
        downloadUrl: url,
        storagePath: path,
        mimeType: 'image/jpeg',
        sizeBytes: bytes.length,
        uploadedAt: DateTime.now(),
      );
    } on FirebaseException catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeLogoStorageService.uploadOfficeLogoBytes', e, st);
      if (FirebaseStorageAvailability.isUnavailableError(e)) return null;
      return null;
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeLogoStorageService.uploadOfficeLogoBytes', e, st);
      return null;
    }
  }

  Future<void> deleteStoredObject(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return;
    if (!await FirebaseStorageAvailability.checkUsable()) return;
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeLogoStorageService.deleteStoredObject', e, st);
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('OfficeLogoStorageService.deleteStoredObject', e, st);
    }
  }
}
