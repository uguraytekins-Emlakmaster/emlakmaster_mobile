import 'package:emlakmaster_mobile/core/platform/file_stub.dart'
    if (dart.library.io) 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/storage/storage_paths.dart';
import 'package:emlakmaster_mobile/core/storage/storage_upload_result.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Profil avatar: `users/{uid}/avatar/avatar_256.jpg` + Firestore meta.
/// Mobil: File ile; Web: uploadAvatarFromBytes ile.
class ProfileAvatarService {
  ProfileAvatarService._();
  static final instance = ProfileAvatarService._();

  FirebaseFirestore get _store => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  static Future<Uint8List> _resizeAndCompressBytes(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    final resized = img.copyResize(image, width: 256, height: 256, interpolation: img.Interpolation.cubic);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
  }

  /// Dosya yolundan resmi okuyup 256x256'e küçültür (sadece mobil).
  Future<Uint8List> _resizeAndCompress(io.File file) async {
    final bytes = await file.readAsBytes();
    return _resizeAndCompressBytes(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  }

  /// Profil fotoğrafını yükler (mobil: File; web'de bu metot çağrılmamalı).
  Future<StorageUploadResult?> uploadAvatar({required String uid, required io.File file}) async {
    try {
      final data = await _resizeAndCompress(file);
      return _uploadData(uid, data);
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('ProfileAvatarService.uploadAvatar', e, st);
      return null;
    }
  }

  /// Web / bytes ile yükleme (image_picker readAsBytes sonrası).
  Future<StorageUploadResult?> uploadAvatarFromBytes({required String uid, required Uint8List bytes}) async {
    try {
      final data = await _resizeAndCompressBytes(bytes);
      return _uploadData(uid, data);
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('ProfileAvatarService.uploadAvatarFromBytes', e, st);
      return null;
    }
  }

  Future<StorageUploadResult?> _uploadData(String uid, Uint8List data) async {
    if (!await FirebaseStorageAvailability.checkUsable()) return null;
    final storagePath = StoragePaths.userAvatar(uid);
    try {
      // Eski düz dosya adı (users/uid/avatar_256.jpg) — taşıma sonrası temizlik
      await _storage.ref().child('users').child(uid).child('avatar_256.jpg').delete().catchError((_) {});

      final ref = _storage.ref(storagePath);
      final task = await ref.putData(
        data,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=86400',
        ),
      );
      final url = await task.ref.getDownloadURL();
      final uploadedAt = DateTime.now();
      await _store.collection(AppConstants.colUsers).doc(uid).set(
        {
          'avatarUrl': url,
          'avatarStoragePath': storagePath,
          'avatarMimeType': 'image/jpeg',
          'avatarSizeBytes': data.length,
          'avatarUploadedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return StorageUploadResult(
        downloadUrl: url,
        storagePath: storagePath,
        mimeType: 'image/jpeg',
        sizeBytes: data.length,
        uploadedAt: uploadedAt,
      );
    } on FirebaseException catch (e, st) {
      if (kDebugMode) AppLogger.e('ProfileAvatarService._uploadData', e, st);
      if (FirebaseStorageAvailability.isUnavailableError(e)) return null;
      return null;
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('ProfileAvatarService._uploadData', e, st);
      return null;
    }
  }

  /// Profil fotoğrafını siler (Storage + Firestore alanı boşaltılır).
  Future<void> deleteAvatar({required String uid}) async {
    try {
      final usable = await FirebaseStorageAvailability.checkUsable();
      if (usable) {
        await _storage.ref(StoragePaths.userAvatar(uid)).delete().catchError((_) {});
        await _storage.ref().child('users').child(uid).child('avatar_256.jpg').delete().catchError((_) {});
      }
      await _store.collection(AppConstants.colUsers).doc(uid).set(
        {
          'avatarUrl': FieldValue.delete(),
          'avatarStoragePath': FieldValue.delete(),
          'avatarMimeType': FieldValue.delete(),
          'avatarSizeBytes': FieldValue.delete(),
          'avatarUploadedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      if (kDebugMode) AppLogger.e('ProfileAvatarService.deleteAvatar', e, st);
    }
  }
}
