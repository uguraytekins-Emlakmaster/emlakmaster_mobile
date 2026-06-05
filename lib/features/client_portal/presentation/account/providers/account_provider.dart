import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Hesabım — tek türetilmiş snapshot.
/// Tek canlı sinyal auth durumudur (e-posta/ad/oturum/doğrulama/üyelik); ek
/// provider okuması yok (provider spam yok). Auth yüklenirken oturumsuz kabul
/// edilir (ilk boya bloklanmaz). Yalnızca auth akışı hata verirse hata yüzeye
/// taşınır (retry).
final accountSnapshotProvider = Provider<AsyncValue<AccountSnapshot>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  if (userAsync.hasError && !userAsync.hasValue) {
    return AsyncValue.error(
      userAsync.error!,
      userAsync.stackTrace ?? StackTrace.current,
    );
  }

  final user = userAsync.valueOrNull;
  final appVersion = AppConstants.appVersion.split('+').first;

  if (user == null) {
    return AsyncValue.data(
      computeAccountSnapshot(
        signedIn: false,
        emailVerified: false,
        appVersion: appVersion,
      ),
    );
  }

  final created = user.metadata.creationTime;
  final memberSinceLabel =
      created != null ? DateFormat('dd.MM.yyyy').format(created) : null;

  return AsyncValue.data(
    computeAccountSnapshot(
      signedIn: true,
      email: user.email,
      displayName: user.displayName,
      phone: user.phoneNumber,
      memberSinceLabel: memberSinceLabel,
      emailVerified: user.emailVerified,
      appVersion: appVersion,
    ),
  );
});
