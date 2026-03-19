// Web'de dart:io yok; Platform kullanımı için stub.
// Koşullu import: if (dart.library.io) 'dart:io' as io kullanılır.

class Platform {
  Platform._();
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
}
