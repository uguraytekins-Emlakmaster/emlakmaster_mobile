import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage kullanılabilir mi — `storageBucket` yapılandırmasına göre (bloklamaz).
final firebaseStorageAvailableProvider = FutureProvider<bool>((ref) async {
  return FirebaseStorageAvailability.checkUsable();
});
