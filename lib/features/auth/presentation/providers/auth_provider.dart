import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/dev/dev_office_fallback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_service.dart';
import '../../../office/data/office_membership_repository.dart';
import '../../../office/data/office_repository.dart';
import '../../../office/domain/office_access_state.dart';
import '../../../office/domain/office_entity.dart';
import '../../../office/domain/office_exception.dart';
import '../../../office/domain/office_membership_entity.dart';
import '../../../office/domain/office_role.dart';
import '../../data/user_repository.dart';
import '../../domain/entities/app_role.dart';

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

/// `users.officeId` ile uyumlu birincil üyelik (`{uid}_{officeId}`).
/// Durum [deriveOfficeAccessState] ile birleştirilir; rol için [currentRoleProvider].
final primaryMembershipProvider = StreamProvider.autoDispose<OfficeMembership?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return Stream<OfficeMembership?>.value(null);
  }
  return UserRepository.userDocStream(user.uid).asyncExpand((doc) {
    if (DevOfficeFallback.isActive) {
      return Stream<OfficeMembership?>.value(
        DevOfficeFallback.syntheticMembership(user.uid),
      );
    }
    final oid = doc?.officeId;
    return OfficeMembershipRepository.watchPrimaryMembershipForUser(user.uid, oid);
  });
});

/// Geriye dönük uyumluluk.
@Deprecated('Use primaryMembershipProvider')
final membershipProvider = primaryMembershipProvider;

/// Ofis erişim durumu (routing / shell).
final officeAccessStateProvider = Provider<AsyncValue<OfficeAccessState>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return const AsyncValue.data(OfficeAccessState.noOfficeContext);
  }
  final docAsync = ref.watch(userDocStreamProvider(user.uid));
  final memAsync = ref.watch(primaryMembershipProvider);
  if (docAsync.isLoading || memAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (docAsync.hasError) {
    return AsyncValue.error(docAsync.error!, docAsync.stackTrace ?? StackTrace.current);
  }
  if (memAsync.hasError) {
    return AsyncValue.error(memAsync.error!, memAsync.stackTrace ?? StackTrace.current);
  }
  final doc = docAsync.valueOrNull;
  final mem = memAsync.valueOrNull;
  final devFb = isDevMode && DevOfficeFallback.isActive;
  return AsyncValue.data(
    deriveOfficeAccessState(
      userDoc: doc,
      primaryMembership: mem,
      userDocLoading: false,
      membershipLoading: false,
      devOfficeFallback: devFb,
    ),
  );
});

/// Ofis bağlamındaki rol veya (ofis yokken) `users.role` yedek.
///
/// Phase 1.3: `officeId` + geçerli iş akışı için [OfficeMembership.role] tek doğruluk kaynağıdır.
/// `users.role` yalnızca ofis öncesi veya üyelik yüklenirken legacy fallback’tür.
final currentRoleProvider = Provider<AsyncValue<AppRole>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.data(AppRole.guest);
  final doc = ref.watch(userDocStreamProvider(user.uid)).valueOrNull;
  if (doc == null) return const AsyncValue.data(AppRole.guest);
  final devFb = isDevMode && DevOfficeFallback.isActive;
  final hasOffice = (doc.officeId != null && doc.officeId!.isNotEmpty) || devFb;
  if (!hasOffice) {
    return AsyncValue.data(AppRole.fromFirestoreRole(doc.role));
  }
  final access = ref.watch(officeAccessStateProvider);
  return access.when(
    data: (state) {
      switch (state) {
        case OfficeAccessState.loading:
          return const AsyncValue.loading();
        case OfficeAccessState.noOfficeContext:
          return AsyncValue.data(AppRole.fromFirestoreRole(doc.role));
        case OfficeAccessState.officeReady:
          final m = ref.watch(primaryMembershipProvider).valueOrNull;
          if (m == null) return const AsyncValue.loading();
          return AsyncValue.data(m.role.toAppRole());
        case OfficeAccessState.membershipMissing:
        case OfficeAccessState.inconsistentPointer:
          return AsyncValue.error(
            OfficeException(
              OfficeErrorCode.membershipMissing,
              'Ofis üyeliğiniz doğrulanamadı. Kurtarma ekranına yönlendirileceksiniz.',
            ),
            StackTrace.current,
          );
        case OfficeAccessState.invitedOnly:
          return AsyncValue.error(
            OfficeException(
              OfficeErrorCode.membershipMissing,
              'Davetiniz henüz tamamlanmadı — tam uygulama erişimi yok.',
            ),
            StackTrace.current,
          );
        case OfficeAccessState.suspended:
          return AsyncValue.error(
            OfficeException(
              OfficeErrorCode.membershipSuspended,
              'Bu ofiste hesabınız askıya alınmış.',
            ),
            StackTrace.current,
          );
        case OfficeAccessState.removed:
          return AsyncValue.error(
            OfficeException(
              OfficeErrorCode.membershipRemoved,
              'Bu ofis için üyeliğiniz sonlandırılmış.',
            ),
            StackTrace.current,
          );
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Firestore `offices/{officeId}` — `users.officeId` ile uyumlu.
final currentOfficeProvider = StreamProvider.autoDispose<Office?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  if (isDevMode && DevOfficeFallback.isActive) {
    return Stream.value(
      Office(
        id: kLocalDevOfficeId,
        name: DevOfficeFallback.officeName,
        createdBy: user.uid,
      ),
    );
  }
  final doc = ref.watch(userDocStreamProvider(user.uid)).valueOrNull;
  final oid = doc?.officeId;
  if (oid == null || oid.isEmpty) return Stream.value(null);
  return OfficeRepository.watchOffice(oid);
});

/// Üyelikteki ofis rolü (yüklenene kadar null).
final officeRoleProvider = Provider<AsyncValue<OfficeRole?>>((ref) {
  final m = ref.watch(primaryMembershipProvider);
  return m.when(
    data: (mem) => AsyncValue.data(mem?.role),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Kullanıcı doc’u var ama `officeId` yok → ofis oluştur / katıl akışı.
final needsOfficeSetupProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  if (isDevMode && DevOfficeFallback.isActive) return false;
  final doc = ref.watch(userDocStreamProvider(user.uid)).valueOrNull;
  if (doc == null) return false;
  final o = doc.officeId;
  return o == null || o.isEmpty;
});

/// `officeId` var ama aktif ofis erişimi yok — kurtarma / davet / askı durumları.
final needsOfficeRecoveryProvider = Provider<bool>((ref) {
  final access = ref.watch(officeAccessStateProvider);
  final v = access.valueOrNull;
  if (v == null) return false;
  return const {
    OfficeAccessState.membershipMissing,
    OfficeAccessState.inconsistentPointer,
    OfficeAccessState.invitedOnly,
    OfficeAccessState.suspended,
    OfficeAccessState.removed,
  }.contains(v);
});

/// Davet e-postası / `invited` durumu (ileride genişletilir).
final invitedPendingProvider = Provider<bool>((ref) => false);

/// Ofis + aktif üyelik hazır.
final officeReadyProvider = Provider<bool>((ref) {
  final access = ref.watch(officeAccessStateProvider);
  return access.valueOrNull == OfficeAccessState.officeReady;
});

/// İlk giriş: kullanıcı var ama Firestore users doc yok. Rol seçim sayfasına yönlendir.
final needsRoleSelectionProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  final docAsync = ref.watch(userDocStreamProvider(user.uid));
  return docAsync.hasValue && docAsync.valueOrNull == null;
});

/// `users/{uid}` Firestore stream henüz ilk snapshot'ı vermediyse true — router/shell agresif yönlendirme yapmamalı.
final userDocBootstrapPendingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  final docAsync = ref.watch(userDocStreamProvider(user.uid));
  return docAsync.isLoading;
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
