import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_command_surface.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin → Kadro: danışman roster, filtreler, ekip yönetimi girişi (Screen 12).
class AdminConsultantsPage extends ConsumerWidget {
  const AdminConsultantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    if (!FeaturePermission.canManageConsultants(currentRole)) {
      final l10n = AppLocalizations.of(context);
      return PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.t('access_denied'),
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
    final canEditTeamRole = FeaturePermission.canManageTeams(currentRole);
    final canInvite = FeaturePermission.canInviteAgents(currentRole);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ShellScreenReadyListener(
          screenName: 'admin_consultants',
          provider: adminConsultantsListProvider,
          itemCount: (v) => (v as List).length,
          child: KadroCommandSurface(
            canEditTeamRole: canEditTeamRole,
            onEditConsultant: (ctx, user) => _showEditConsultantDialog(
              ctx,
              ref,
              user,
            ),
            headerActions: [
              if (canInvite)
                IconButton(
                  icon: const Icon(Icons.person_add_rounded),
                  iconSize: AdminKadroTokens.rowTitleSize + 8,
                  tooltip: l10n.t('action_add_consultant'),
                  onPressed: () => _showAddConsultantDialog(context, ref),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showAddConsultantDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    String fullName = '';
    String email = '';
    String inviteRole = AppRole.agent.id;
    String? teamId;
    final teams = await ref.read(adminConsultantsTeamsProvider.future);
    if (teams.isNotEmpty) teamId = teams.first.id;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppThemeExtension.of(context).surface,
              title: Text(
                l10n.t('action_add_consultant'),
                style: TextStyle(
                  color: AppThemeExtension.of(context).textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('full_name'),
                        labelStyle: TextStyle(
                          color: AppThemeExtension.of(context).textSecondary,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                      ),
                      onChanged: (v) => fullName = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('label_email'),
                        labelStyle: TextStyle(
                          color: AppThemeExtension.of(context).textSecondary,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                      ),
                      onChanged: (v) => email = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: inviteRole,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_role'),
                        border: const OutlineInputBorder(),
                      ),
                      dropdownColor: AppThemeExtension.of(context).surface,
                      items: [AppRole.agent, AppRole.teamLead, AppRole.officeManager]
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                r.label,
                                style: TextStyle(
                                  color: AppThemeExtension.of(context).textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => inviteRole = v ?? inviteRole),
                    ),
                    if (teams.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.space4),
                      DropdownButtonFormField<String>(
                        initialValue: teamId,
                        decoration: InputDecoration(
                          labelText: l10n.t('label_team'),
                          border: const OutlineInputBorder(),
                        ),
                        dropdownColor: AppThemeExtension.of(context).surface,
                        items: teams
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.name,
                                  style: TextStyle(
                                    color:
                                        AppThemeExtension.of(context).textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => teamId = v),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      l10n.t('consultant_invite_info'),
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.t('cancel')),
                ),
                FilledButton(
                  onPressed: () async {
                    if (email.trim().isEmpty) return;
                    final createdBy =
                        ref.read(currentUserProvider).valueOrNull?.uid ?? '';
                    if (createdBy.isEmpty) return;
                    try {
                      await FirestoreService.createInvite(
                        email: email.trim(),
                        role: inviteRole,
                        createdBy: createdBy,
                        teamId: teamId,
                        name: fullName.trim().isEmpty ? null : fullName.trim(),
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.t('consultant_invite_saved')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.t('error_generic'))),
                        );
                      }
                    }
                  },
                  child: Text(l10n.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _showEditConsultantDialog(
    BuildContext context,
    WidgetRef ref,
    UserDoc u,
  ) async {
    final l10n = AppLocalizations.of(context);
    final teams = await ref.read(adminConsultantsTeamsProvider.future);
    if (!context.mounted) return;

    String role = u.role;
    String? teamId = u.teamId;
    var isActive = u.isActive;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppThemeExtension.of(context).surface,
              title: Text(
                l10n.t('edit_consultant'),
                style: TextStyle(
                  color: AppThemeExtension.of(context).textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      u.name ?? u.email ?? u.uid,
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_role'),
                        border: const OutlineInputBorder(),
                      ),
                      dropdownColor: AppThemeExtension.of(context).surface,
                      items: [
                        AppRole.agent,
                        AppRole.teamLead,
                        AppRole.officeManager,
                        AppRole.generalManager,
                        AppRole.brokerOwner,
                      ]
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => role = v ?? role),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String?>(
                      initialValue: teamId,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_team'),
                        border: const OutlineInputBorder(),
                      ),
                      dropdownColor: AppThemeExtension.of(context).surface,
                      items: [
                        DropdownMenuItem<String?>(
                          child: Text(l10n.t('filter_team_all')),
                        ),
                        ...teams.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => teamId = v),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Row(
                      children: [
                        Text(l10n.t('is_active')),
                        const SizedBox(width: DesignTokens.space2),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setState(() => isActive = v),
                        ),
                      ],
                    ),
                    Text(
                      l10n.t('password_reset_info'),
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textTertiary,
                        fontSize: DesignTokens.fontSizeXs,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.t('cancel')),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      final managerId = teamId != null &&
                              teams.any((t) => t.id == teamId)
                          ? teams.firstWhere((t) => t.id == teamId).managerId
                          : null;
                      final oldTeamId = u.teamId;
                      if (oldTeamId != teamId) {
                        if (oldTeamId != null && oldTeamId.isNotEmpty) {
                          await FirestoreService.removeAgentFromTeam(
                            u.uid,
                            oldTeamId,
                          );
                        }
                        await UserRepository.setUserDoc(
                          uid: u.uid,
                          role: role,
                          name: u.name,
                          email: u.email,
                          isActive: isActive,
                          teamId: teamId,
                          managerId: managerId,
                        );
                        final newTeamId = teamId;
                        if (newTeamId != null && newTeamId.isNotEmpty) {
                          await FirestoreService.assignAgentToTeam(
                            u.uid,
                            newTeamId,
                          );
                        }
                      } else {
                        await UserRepository.setUserDoc(
                          uid: u.uid,
                          role: role,
                          name: u.name,
                          email: u.email,
                          isActive: isActive,
                          teamId: teamId,
                          managerId: managerId,
                        );
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.t('saved_success')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(l10n.t('error_generic'))),
                        );
                      }
                    }
                  },
                  child: Text(l10n.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
