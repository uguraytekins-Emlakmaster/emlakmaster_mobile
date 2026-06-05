import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/ekipler_actions.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class EkipDetayActions {
  EkipDetayActions._();

  static void openTeams(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminTeams);
  }

  static void openKadro(BuildContext context) => EkiplerActions.openKadro(context);

  static void openReportsTab(BuildContext context) =>
      EkiplerActions.openReportsTab(context);

  static void openCommandCenter(BuildContext context) =>
      EkiplerActions.openCommandCenter(context);

  static void openWarRoom(BuildContext context) =>
      EkiplerActions.openWarRoom(context);

  static bool canOpenCommandCenter(WidgetRef ref) =>
      EkiplerActions.canOpenCommandCenter(ref);

  static bool canOpenWarRoom(WidgetRef ref) => EkiplerActions.canOpenWarRoom(ref);

  static bool canManageTeam(WidgetRef ref) {
    final role = ref.read(displayRoleOrNullProvider) ?? AppRole.guest;
    return FeaturePermission.canManageTeams(role);
  }
}
