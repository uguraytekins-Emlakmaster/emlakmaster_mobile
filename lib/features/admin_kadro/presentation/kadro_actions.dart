import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class KadroActions {
  KadroActions._();

  static void openTeams(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminTeams);
  }

  static void openReportsTab(BuildContext context) {
    AppFeedback.selectionClick();
    AdminShellNav.goToReportsTab(context);
  }

  static void openCommandCenter(BuildContext context) {
    AppFeedback.selectionClick();
    AdminShellNav.goToCommandCenterTab(context);
  }

  static void openWarRoom(BuildContext context) {
    AppFeedback.selectionClick();
    AdminShellNav.goToWarRoomTab(context);
  }

  static void openTeamDetail(BuildContext context, String teamId) {
    if (teamId.isEmpty) return;
    AppFeedback.selectionClick();
    context.push(AppRouter.adminTeamDetailPath(teamId));
  }

  static bool canOpenCommandCenter(WidgetRef ref) {
    final role = ref.read(displayRoleOrNullProvider) ?? AppRole.guest;
    return FeaturePermission.canViewAllCalls(role);
  }

  static bool canOpenWarRoom(WidgetRef ref) {
    final role = ref.read(displayRoleOrNullProvider) ?? AppRole.guest;
    return FeaturePermission.canViewWarRoom(role);
  }

  static bool canManageTeams(WidgetRef ref) {
    final role = ref.read(displayRoleOrNullProvider) ?? AppRole.guest;
    return FeaturePermission.canManageTeams(role);
  }
}
