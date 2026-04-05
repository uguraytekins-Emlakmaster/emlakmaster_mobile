import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage yok veya bucket yapılandırılmamışsa yükleme akışlarını yumuşak şekilde kapatır.
///
/// **Önemli:** Kök dizindeki (`__availability_probe_*.bin`) sonda [storage.rules] içindeki
/// `match /{allPaths=**}` kuralı okumayı reddeder → `storage/unauthorized` gelir ve Storage
/// aslında açık olsa bile "kapalı" sanılır. Sonda, kurallarda okumaya izin verilen
/// `users/{uid}/avatar/{fileName}` altında `getMetadata` (nesne yok → object-not-found) kullanılır.
class FirebaseStorageAvailability {
  FirebaseStorageAvailability._();

  static const String unavailableMessage = 'Storage henüz aktif değil';

  static bool? _cached;
  static String? _cacheKey;

  /// Önbelleği sıfırla (ör. Firebase yeniden yapılandırıldığında).
  static void clearCache() {
    _cached = null;
    _cacheKey = null;
  }

  /// Varsayılan bucket ile okuma/yazma bekleniyorsa `true`.
  static Future<bool> checkUsable() async {
    if (Firebase.apps.isEmpty) return false;
    final bucket = FirebaseStorage.instance.app.options.storageBucket;
    if (bucket == null || bucket.isEmpty) return false;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final key = '$bucket|${uid ?? ''}';
    if (_cached != null && _cacheKey == key) return _cached!;

    final ok = await _probe(uid: uid);
    _cached = ok;
    _cacheKey = key;
    return ok;
  }

  static Future<bool> _probe({String? uid}) async {
    try {
      if (uid == null || uid.isEmpty) {
        // Console'da bucket atanmış = Storage projede tanımlı; dosya yolu doğrulaması giriş sonrası yapılır.
        return true;
      }
      final ref = FirebaseStorage.instance.ref(
        'users/$uid/avatar/__availability_probe.bin',
      );
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'storage/object-not-found') {
        return true;
      }
      if (_unavailableCodes.contains(e.code)) return false;
      if (e.code.startsWith('storage/')) return false;
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirebaseStorageAvailability] probe: $e');
        debugPrint('$st');
      }
      return false;
    }
  }

  static const Set<String> _unavailableCodes = {
    'storage/bucket-not-found',
    'storage/invalid-argument',
    'storage/project-not-found',
  };

  /// [catch] bloklarında: bucket / init / ağ hatalarında yükleme anlamlı değil.
  static bool isUnavailableError(Object error) {
    if (error is FirebaseException) {
      final c = error.code;
      if (c == 'storage/object-not-found') return false;
      if (c.startsWith('storage/')) return true;
    }
    final s = error.toString().toLowerCase();
    if (s.contains('firebase_storage') && s.contains('not')) return true;
    if (s.contains('bucket') && (s.contains('not found') || s.contains('not-found'))) {
      return true;
    }
    return false;
  }
}
