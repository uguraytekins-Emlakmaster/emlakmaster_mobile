import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage kullanılabilirliği — yükleme akışlarında yumuşak kontrol.
///
/// **Aktif sayılma kuralı:** [FirebaseOptions.storageBucket] doluysa Storage bu uygulama
/// yapılandırmasında etkindir; UI’da “depolama kapalı” göstermeyiz.
/// Gerçek yükleme/izin hataları upload sırasında yakalanır ([isUnavailableError]).
///
/// Firebase Console’da **Build → Storage** ürününün başlatılmış ve `storage.rules`
/// deploy edilmiş olması gerekir; bu sınıf sadece istemci tarafındaki bucket alanını doğrular.
class FirebaseStorageAvailability {
  FirebaseStorageAvailability._();

  static const String unavailableMessage = 'Storage henüz aktif değil';

  static bool? _cached;
  static String? _cacheBucket;

  /// Önbelleği sıfırla (ör. Firebase yeniden yapılandırıldığında).
  static void clearCache() {
    _cached = null;
    _cacheBucket = null;
  }

  /// [DefaultFirebaseOptions] içinde `storageBucket` tanımlıysa `true`.
  static Future<bool> checkUsable() async {
    if (Firebase.apps.isEmpty) return false;
    final bucket = FirebaseStorage.instance.app.options.storageBucket;
    if (bucket == null || bucket.isEmpty) return false;

    if (_cached != null && _cacheBucket == bucket) return _cached!;
    _cached = true;
    _cacheBucket = bucket;
    return true;
  }

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
