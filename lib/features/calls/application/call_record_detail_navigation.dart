import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Çağrı özeti ekranına geçiş (kayıt oynatma yok).
abstract final class CallRecordDetailNavigation {
  CallRecordDetailNavigation._();

  static void openSummary(
    BuildContext context, {
    required String? firestoreDocId,
    VoidCallback? onFallback,
  }) {
    final docId = firestoreDocId?.trim();
    if (docId != null && docId.isNotEmpty) {
      context.push(
        AppRouter.routeCallSummary,
        extra: {'callDocId': docId},
      );
      return;
    }
    onFallback?.call();
  }
}
