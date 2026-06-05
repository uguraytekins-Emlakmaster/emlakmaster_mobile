import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/admin_islem_kayitlari/presentation/utils/islem_kayitlari_types.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class IslemKayitlariActions {
  IslemKayitlariActions._();

  static void openTeam(BuildContext context, String? teamId) {
    if (teamId == null || teamId.isEmpty) return;
    AppFeedback.selectionClick();
    context.push(AppRouter.adminTeamDetailPath(teamId));
  }

  static void openKadro(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminConsultants);
  }

  static void openReportsTab(BuildContext context) {
    AppFeedback.selectionClick();
    AdminShellNav.goToReportsTab(context);
  }

  static void openCommandCenter(BuildContext context) {
    AppFeedback.selectionClick();
    AdminShellNav.goToCommandCenterTab(context);
  }

  static bool canOpenCommandCenter(WidgetRef ref) {
    final role = ref.read(displayRoleOrNullProvider) ?? AppRole.guest;
    return FeaturePermission.canViewAllCalls(role);
  }

  static void showDetailSheet(
    BuildContext context,
    IslemKayitlariRowViewModel row,
  ) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Kaynak', value: row.sourceLabel),
                _DetailLine(label: 'Aktör', value: row.actorLine),
                if (row.targetLine.isNotEmpty)
                  _DetailLine(label: 'Hedef', value: row.targetLine),
                _DetailLine(label: 'Zaman', value: row.timestampLabel),
                if (row.detailLine.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    row.detailLine,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
                if (row.hasPartialMetadata) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Bazı alanlar kayıtta eksik; yalnızca Firestore\'daki mevcut metadata gösterilir.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static void applyFilterFromRow(
    void Function(IslemKayitlariFilter filter) onFilter,
    IslemKayitlariRowViewModel row,
  ) {
    AppFeedback.selectionClick();
    onFilter(row.suggestedFilter);
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
