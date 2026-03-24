import 'dart:typed_data';

import 'package:emlakmaster_mobile/core/platform/file_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Ofis logosu yüklemek için Firebase Storage (app_settings/listing_display ile birlikte kullan).
/// Mobil: uploadLogo(File); Web: uploadLogoBytes(Uint8List).
/// Storage yoksa `null` döner (UI yumuşak uyarı gösterir).
class LogoStorageService {
  LogoStorageService._();
  static final LogoStorageService instance = LogoStorageService._();

  static const String _pathPrefix = 'listing_display';
  static const String _logoFileName = 'company_logo';

  /// Seçilen dosyayı yükleyip indirme URL'si döner (sadece mobil; web'de uploadLogoBytes kullanın).
  Future<String?> uploadLogo(io.File file) async {
    if (kIsWeb) throw UnsupportedError('Use uploadLogoBytes on web');
    if (!await FirebaseStorageAvailability.checkUsable()) return null;
    try {
      final bytes = await file.readAsBytes();
      final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final ref = FirebaseStorage.instance
          .ref()
          .child(_pathPrefix)
          .child('$_logoFileName${DateTime.now().millisecondsSinceEpoch}.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
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
      final ref = FirebaseStorage.instance
          .ref()
          .child(_pathPrefix)
          .child('$_logoFileName${DateTime.now().millisecondsSinceEpoch}.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (FirebaseStorageAvailability.isUnavailableError(e)) return null;
      return null;
    }
  }
}
