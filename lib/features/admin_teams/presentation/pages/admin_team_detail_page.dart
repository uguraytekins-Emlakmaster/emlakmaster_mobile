import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/pages/admin_consultants_page.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/providers/ekip_detay_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/widgets/ekip_detay_command_surface.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/providers/admin_teams_providers.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin → Ekip detay: tek ekip operasyon yüzeyi (Screen 14).
class AdminTeamDetailPage extends ConsumerStatefulWidget {
  const AdminTeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<AdminTeamDetailPage> createState() =>
      _AdminTeamDetailPageState();
}

class _AdminTeamDetailPageState extends ConsumerState<AdminTeamDetailPage> {
  String? _selectedManagerId;

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    if (!FeaturePermission.canManageTeams(currentRole)) {
      return PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).t('access_denied'),
                style: TextStyle(
                  color: AppThemeExtension.of(context).textSecondary,
                  fontSize: DesignTokens.fontSizeSm,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final canManage = FeaturePermission.canManageTeams(currentRole);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: EkipDetayCommandSurface(
          teamId: widget.teamId,
          selectedManagerId: _selectedManagerId ?? '',
          onManagerChanged: (id) => setState(() => _selectedManagerId = id),
          onSaveManager: () => _saveManager(context),
          onEditConsultant: (ctx, user) =>
              AdminConsultantsPage.showEditConsultantDialog(ctx, ref, user),
          onAddMember: () => _showAddMemberDialog(context),
          onRemoveMember: (ctx, user) => _confirmRemoveMember(ctx, user),
          headerActions: [
            if (canManage)
              IconButton(
                icon: const Icon(Icons.person_add_rounded),
                iconSize: AdminEkipDetayTokens.rowTitleSize + 8,
                tooltip: l10n.t('action_add_member'),
                onPressed: () => _showAddMemberDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveManager(BuildContext context) async {
    final teamAsync = ref.read(adminTeamDocProvider(widget.teamId));
    final team = teamAsync.valueOrNull;
    if (team == null) return;

    final managerId = _selectedManagerId ?? team.managerId;
    if (managerId.isEmpty) return;

    try {
      await FirestoreService.updateTeamManager(team.id, managerId);
      ref.invalidate(ekipDetaySnapshotProvider(widget.teamId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('manager_updated')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).t('error_generic')} $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final consultants = await ref.read(adminConsultantsListProvider.future);
    final team = await ref.read(adminTeamDocProvider(widget.teamId).future);
    if (!context.mounted || team == null) return;

    final currentMemberIds = team.memberIds;
    final available = consultants
        .where((u) => !currentMemberIds.contains(u.uid))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('no_consultants_to_add'))),
      );
      return;
    }

    final selected = <String>{};
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppThemeExtension.of(context).surface,
              title: Text(
                l10n.t('action_add_member'),
                style: TextStyle(
                  color: AppThemeExtension.of(context).textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final u = available[i];
                    final isSelected = selected.contains(u.uid);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(
                        u.name ?? u.email ?? u.uid,
                        style: TextStyle(
                          color: AppThemeExtension.of(context).textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        u.email ?? u.role,
                        style: TextStyle(
                          color: AppThemeExtension.of(context).textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      activeColor: AppThemeExtension.of(context).accent,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selected.add(u.uid);
                          } else {
                            selected.remove(u.uid);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    l10n.t('cancel'),
                    style: TextStyle(
                      color: AppThemeExtension.of(context).textSecondary,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    for (final uid in selected) {
                      await FirestoreService.assignAgentToTeam(
                        uid,
                        widget.teamId,
                      );
                    }
                    ref.invalidate(ekipDetaySnapshotProvider(widget.teamId));
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppThemeExtension.of(context).accent,
                  ),
                  child: Text(l10n.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, UserDoc user) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeExtension.of(context).surface,
        title: Text(
          l10n.t('action_remove_from_team'),
          style: TextStyle(color: AppThemeExtension.of(context).textPrimary),
        ),
        content: Text(
          l10n.t('confirm_remove_from_team'),
          style: TextStyle(color: AppThemeExtension.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.t('cancel'),
              style: TextStyle(
                color: AppThemeExtension.of(context).textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeExtension.of(context).danger,
            ),
            child: Text(l10n.t('action_remove_from_team')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirestoreService.removeAgentFromTeam(user.uid, widget.teamId);
      ref.invalidate(ekipDetaySnapshotProvider(widget.teamId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('member_removed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('error_generic'))),
        );
      }
    }
  }
}
