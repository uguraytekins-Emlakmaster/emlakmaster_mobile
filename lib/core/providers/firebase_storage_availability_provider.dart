import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage sondası — UI’da butonları devre dışı bırakmak için (bloklamaz).
/// Oturum değişince yeniden ölçülür (uid’e göre avatar yolu).
final firebaseStorageAvailableProvider = FutureProvider<bool>((ref) async {
  ref.watch(currentUserProvider);
  return FirebaseStorageAvailability.checkUsable();
});
