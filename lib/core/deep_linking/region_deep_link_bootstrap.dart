import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:emlakmaster_mobile/core/deep_linking/pending_deep_link_store.dart';
import 'package:emlakmaster_mobile/core/deep_linking/region_insight_uri.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// `emlakmaster://` / `https://…/region-insight/…` → [GoRouter] + oturum yoksa [PendingDeepLinkStore].
class RegionDeepLinkBootstrap {
  RegionDeepLinkBootstrap._();

  static AppLinks? _appLinks;
  static StreamSubscription<Uri>? _sub;

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _appLinks = null;
  }

  /// [ConsumerStatefulWidget] `initState` içinden çağırın; [ref] aynı widget’tan.
  static Future<void> attach(WidgetRef ref) async {
    if (kIsWeb) return;
    await dispose();
    _appLinks = AppLinks();
    _sub = _appLinks!.uriLinkStream.listen(
      (uri) => _handleUri(ref, uri),
      onError: (Object _) {},
    );
    final initial = await _appLinks!.getInitialLink();
    if (initial != null) {
      _handleUri(ref, initial);
    }
  }

  static void _handleUri(WidgetRef ref, Uri uri) {
    final path = regionInsightPathFromUri(uri);
    if (path == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateIfPossible(ref, path);
    });
  }

  /// Harici çağrı (ör. test) — oturum / bekleyen kuyruk.
  static void navigateIfPossible(WidgetRef ref, String path) {
    if (!path.startsWith('/region-insight')) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    final router = ref.read(AppRouter.goRouterProvider);
    if (user == null) {
      unawaited(PendingDeepLinkStore.save(path));
      return;
    }
    router.go(path);
  }

  /// Giriş tamamlanınca [EmlakMasterApp] içinden çağırın.
  static Future<void> consumePendingAfterAuth(WidgetRef ref) async {
    final pending = await PendingDeepLinkStore.consume();
    if (pending == null || pending.isEmpty) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final router = ref.read(AppRouter.goRouterProvider);
    router.go(pending);
  }
}
