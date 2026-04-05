import 'dart:typed_data';

import 'package:emlakmaster_mobile/core/platform/file_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/storage/storage_paths.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Global vitrin logosu (`app_settings` listing_display) — `listing_display/company_logo_*.jpg`.
/// Ofis bağlamındaki logo için [OfficeLogoStorageService] kullanın.
class LogoStorageService {
  LogoStorageService._();
  static final LogoStorageService instance = LogoStorageService._();

  /// Seçilen dosyayı yükleyip indirme URL'si döner (sadece mobil; web'de uploadLogoBytes kullanın).
  Future<String?> uploadLogo(io.File file) async {
    if (kIsWeb) throw UnsupportedError('Use uploadLogoBytes on web');
    if (!await FirebaseStorageAvailability.checkUsable()) return null;
    try {
      final bytes = await file.readAsBytes();
      final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final name = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref(StoragePaths.listingDisplayLogo(name));
      final metadata = SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=86400');
      await ref.putData(data, metadata);
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (FirebaseStorageAvailability.isUnavailableError(e)) return null;
      return null;
    }
  }

  /// [bytes] ile (örn. web picker) yükleme.
  Future<String?> uploadLogoBytes(Uint8List bytes) async {
    if (!await FirebaseStorageAvailability.checkUsable()) return null;
    try {
      final name = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref(StoragePaths.listingDisplayLogo(name));
      final metadata = SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=86400');
      await ref.putData(bytes, metadata);
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (FirebaseStorageAvailability.isUnavailableError(e)) return null;
      return null;
    }
  }
}
