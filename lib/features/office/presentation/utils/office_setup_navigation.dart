import 'dart:async';

import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_session_coordinator.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ofis oluşturma / davetle katılma sonrası rol grafiğini tazeler ve ana kabuğa
/// güvenli geçiş yapar. Stream invalidation tek başına yavaş cihazlarda yeterli
/// olmayabiliyordu; users.officeId yazıldıktan sonra kısa süre beklenir.
abstract final class OfficeSetupNavigation {
  static const _pollInterval = Duration(milliseconds: 150);
  static const _maxWait = Duration(seconds: 8);

  /// Rol/ofis provider grafiğini yeniler, officeId'nin users doc'a yansımasını
  /// bekler (en fazla [_maxWait]), ardından home'a yönlendirir.
  static Future<void> refreshGraphAndGoHome(
    WidgetRef ref,
    BuildContext context, {
    required String uid,
  }) async {
    AuthSessionCoordinator.invalidateRoleGraph(ref, uid: uid);

    final deadline = DateTime.now().add(_maxWait);
    while (DateTime.now().isBefore(deadline)) {
      if (!context.mounted) return;
      final needsOffice = ref.read(needsOfficeSetupProvider);
      if (!needsOffice) break;
      final doc = await UserRepository.getUserDoc(uid);
      if (doc?.officeId != null && doc!.officeId!.isNotEmpty) break;
      await Future<void>.delayed(_pollInterval);
    }

    if (!context.mounted) return;
    context.go(AppRouter.routeHome);
  }
}
