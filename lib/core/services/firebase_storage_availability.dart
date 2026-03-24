import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage yok veya bucket yapılandırılmamışsa yükleme akışlarını yumuşak şekilde kapatır.
class FirebaseStorageAvailability {
  FirebaseStorageAvailability._();

  static const String unavailableMessage = 'Storage henüz aktif değil';

  static bool? _cached;
  static Future<bool>? _inFlight;

  /// Önbelleği sıfırla (ör. Firebase yeniden yapılandırıldığında).
  static void clearCache() {
    _cached = null;
    _inFlight = null;
  }

  /// Varsayılan bucket ile okuma/yazma bekleniyorsa `true`.
  static Future<bool> checkUsable() async {
    if (_cached != null) return _cached!;
    _inFlight ??= _probeOnce();
    final ok = await _inFlight!;
    _cached = ok;
    return ok;
  }

  static Future<bool> _probeOnce() async {
    try {
      if (Firebase.apps.isEmpty) return false;
      final bucket = FirebaseStorage.instance.app.options.storageBucket;
      if (bucket == null || bucket.isEmpty) return false;
      final ref = FirebaseStorage.instance.ref(
        '__availability_probe_${DateTime.now().millisecondsSinceEpoch}.bin',
      );
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'storage/object-not-found') {
        return true;
      }
      if (e.code == 'storage/unauthorized' && isDevMode) {
        return false;
      }
      if (_unavailableCodes.contains(e.code)) return false;
      if (isDevMode) return false;
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
