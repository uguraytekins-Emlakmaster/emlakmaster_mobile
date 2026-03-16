import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Ofis logosu yüklemek için Firebase Storage (app_settings/listing_display ile birlikte kullan).
class LogoStorageService {
  LogoStorageService._();
  static final LogoStorageService instance = LogoStorageService._();

  static const String _pathPrefix = 'listing_display';
  static const String _logoFileName = 'company_logo';

  /// Seçilen dosyayı yükleyip indirme URL'si döner. [file] galeriden/kameradan gelen dosya.
  Future<String> uploadLogo(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child(_pathPrefix)
        .child('$_logoFileName${DateTime.now().millisecondsSinceEpoch}.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  /// [bytes] ile (örn. web picker) yükleme.
  Future<String> uploadLogoBytes(Uint8List bytes) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child(_pathPrefix)
        .child('$_logoFileName${DateTime.now().millisecondsSinceEpoch}.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}
