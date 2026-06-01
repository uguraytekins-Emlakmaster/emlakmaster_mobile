import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/requests/request_center_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Talep Merkezi — tek türetilmiş snapshot.
/// Kanallar statiktir; tek canlı sinyal auth durumudur. Auth yüklenirken
/// oturumsuz kabul edilir (ilk boya bloklanmaz). Yalnızca auth akışı hata
/// verirse hata durumu yüzeye taşınır (retry).
final requestCenterSnapshotProvider =
    Provider<AsyncValue<RequestCenterSnapshot>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  if (userAsync.hasError && !userAsync.hasValue) {
    return AsyncValue.error(
      userAsync.error!,
      userAsync.stackTrace ?? StackTrace.current,
    );
  }

  final user = userAsync.valueOrNull;
  return AsyncValue.data(
    computeRequestCenterSnapshot(
      signedIn: user != null,
      displayName: user?.displayName,
    ),
  );
});
