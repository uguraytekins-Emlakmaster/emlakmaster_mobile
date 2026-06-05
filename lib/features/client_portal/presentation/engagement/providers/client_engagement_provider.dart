import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/engagement/client_engagement_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// İlgi & Etkileşim — tek türetilmiş snapshot.
/// Kanallar statiktir; tek canlı sinyal auth durumudur. Auth yüklenirken
/// oturumsuz kabul edilir (ilk boya bloklanmaz). Yalnızca auth akışı hata
/// verirse hata durumu yüzeye taşınır (retry).
final clientEngagementSnapshotProvider =
    Provider<AsyncValue<ClientEngagementSnapshot>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  if (userAsync.hasError && !userAsync.hasValue) {
    return AsyncValue.error(userAsync.error!, userAsync.stackTrace ?? StackTrace.current);
  }

  final user = userAsync.valueOrNull;
  return AsyncValue.data(
    computeClientEngagementSnapshot(
      signedIn: user != null,
      displayName: user?.displayName,
      previewPortfolioCount: clientPortalPreviewCatalog.length,
    ),
  );
});
