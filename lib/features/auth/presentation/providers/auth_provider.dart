import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user_repository.dart';
import '../../domain/entities/app_role.dart';
import '../../../../core/services/auth_service.dart';

/// Mevcut Firebase Auth kullanıcısı. null = çıkış yapılmış.
final currentUserProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// users/{uid} stream. Rol değişikliklerini canlı dinler.
final userDocStreamProvider =
    StreamProvider.autoDispose.family<UserDoc?, String>((ref, uid) {
  return UserRepository.userDocStream(uid);
});

/// İlk girişte users doc yoksa rol seçim ekranı gösterilir; doc burada oluşturulur (ensureUserDoc artık otomatik çağrılmaz).
final ensureUserDocProvider =
    FutureProvider.autoDispose.family<void, String>((ref, uid) async {
  final user = ref.read(currentUserProvider).valueOrNull;
  if (user?.uid != uid) return;
  final existing = await UserRepository.getUserDoc(uid);
  if (existing != null) return;
  final firstAdmin = !await UserRepository.hasAnyUser();
  await UserRepository.setUserDoc(
    uid: uid,
    role: firstAdmin ? 'super_admin' : 'agent',
    name: user!.displayName,
    email: user.email,
  );
});

/// Firestore'dan gelen rol. Doc yoksa loading döner; doc null ise rol seçim ekranı gösterilir (ensureUserDoc tetiklenmez).
final currentRoleProvider = Provider<AsyncValue<AppRole>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return const AsyncValue.data(AppRole.guest);
  final docAsync = ref.watch(userDocStreamProvider(user.uid));
  return docAsync.when(
    loading: () => const AsyncValue.loading(),
    data: (doc) {
      if (doc != null) {
        return AsyncValue.data(AppRole.fromFirestoreRole(doc.role));
      }
      return const AsyncValue.data(AppRole.guest);
    },
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// İlk giriş: kullanıcı var ama Firestore users doc yok. Rol seçim sayfasına yönlendir.
final needsRoleSelectionProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  final docAsync = ref.watch(userDocStreamProvider(user.uid));
  return docAsync.hasValue && docAsync.valueOrNull == null;
});

/// UI için: rol yüklü mü, hata mı, son rol değeri.
final currentRoleOrNullProvider = Provider<AppRole?>((ref) {
  final asyncRole = ref.watch(currentRoleProvider);
  return asyncRole.valueOrNull;
});

/// Yönetici modu: superAdmin/broker test için geçici rol değiştirme. null = gerçek rol kullan.
final overrideRoleProvider = StateProvider<AppRole?>((ref) => null);

/// Gösterilen rol: override varsa o, yoksa Firestore’daki rol.
final displayRoleProvider = Provider<AsyncValue<AppRole>>((ref) {
  final override = ref.watch(overrideRoleProvider);
  if (override != null) return AsyncValue.data(override);
  return ref.watch(currentRoleProvider);
});

/// displayRoleProvider’ın valueOrNull hali (Dashboard/buton için).
final displayRoleOrNullProvider = Provider<AppRole?>((ref) {
  return ref.watch(displayRoleProvider).valueOrNull ?? AppRole.guest;
});

/// Yönetici kullanıcının hangi paneli gördüğü. null = role göre; true = danışman paneli; false = yönetici paneli.
final preferredConsultantPanelProvider = StateProvider<bool?>((ref) => null);
