import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_team_detail_page.dart';

/// Admin → Ekip listesi: ekipler, yeni ekip, detaya geçiş.
class AdminTeamsPage extends ConsumerWidget {
  const AdminTeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    if (!FeaturePermission.canManageTeams(currentRole)) {
      return Scaffold(
        backgroundColor: DesignTokens.backgroundDark,
        appBar: emlakAppBar(
          context,
          backgroundColor: DesignTokens.backgroundDark,
          foregroundColor: DesignTokens.textPrimaryDark,
          title: Text(AppLocalizations.of(context).t('title_admin_teams')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context).t('access_denied'),
              style: const TextStyle(
                color: DesignTokens.textSecondaryDark,
                fontSize: DesignTokens.fontSizeSm,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: emlakAppBar(
        context,
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        title: Text(l10n.t('title_admin_teams')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateTeamDialog(context, ref),
            tooltip: l10n.t('action_add_team'),
          ),
        ],
      ),
      body: StreamBuilder<List<TeamDoc>>(
        stream: FirestoreService.teamsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    TextButton(
                      onPressed: () => _showCreateTeamDialog(context, ref),
                      child: Text(l10n.t('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: DesignTokens.primary),
            );
          }
          final teams = snapshot.data!;
          if (teams.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, size: 64, color: DesignTokens.textTertiaryDark),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      l10n.t('empty_teams_title'),
                      style: const TextStyle(
                        color: DesignTokens.textPrimaryDark,
                        fontSize: DesignTokens.fontSizeLg,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      l10n.t('empty_teams_subtitle'),
                      style: const TextStyle(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space5),
                    FilledButton.icon(
                      onPressed: () => _showCreateTeamDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(l10n.t('action_add_team')),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                        foregroundColor: DesignTokens.brandWhite,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(DesignTokens.space4),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return _TeamListTile(
                    team: team,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminTeamDetailPage(teamId: team.id),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: DesignTokens.space4,
                bottom: DesignTokens.space4,
                child: FloatingActionButton(
                  onPressed: () => _showCreateTeamDialog(context, ref),
                  backgroundColor: DesignTokens.primary,
                  child: const Icon(Icons.add_rounded, color: DesignTokens.brandWhite),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showCreateTeamDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final consultants = await FirestoreService.consultantsStream().first;
    final managers = consultants.where((u) => AppRole.fromFirestoreRole(u.role).isManagerTier).toList();
    String name = '';
    String? managerId = managers.isNotEmpty ? managers.first.uid : null;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(l10n.t('action_add_team'), style: const TextStyle(color: DesignTokens.textPrimaryDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('label_team_name'),
                        labelStyle: const TextStyle(color: DesignTokens.textSecondaryDark),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.primary)),
                      ),
                      style: const TextStyle(color: DesignTokens.textPrimaryDark),
                      onChanged: (v) => name = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: managerId,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_manager'),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                      ),
                      dropdownColor: DesignTokens.surfaceDark,
                      items: managers
                          .map((u) => DropdownMenuItem(
                                value: u.uid,
                                child: Text(
                                  u.name ?? u.email ?? u.uid,
                                  style: const TextStyle(color: DesignTokens.textPrimaryDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => managerId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.t('cancel'), style: const TextStyle(color: DesignTokens.textSecondaryDark)),
                ),
                FilledButton(
                  onPressed: () async {
                    if (name.isEmpty || managerId == null) return;
                    try {
                      await FirestoreService.createTeam(name: name, managerId: managerId!);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('${l10n.t('error_generic')} $e')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: DesignTokens.primary),
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

class _TeamListTile extends StatelessWidget {
  const _TeamListTile({required this.team, required this.onTap});

  final TeamDoc team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space3),
      color: DesignTokens.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
        leading: CircleAvatar(
          backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.groups_rounded, color: DesignTokens.primary),
        ),
        title: Text(
          team.name,
          style: const TextStyle(color: DesignTokens.textPrimaryDark, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${AppLocalizations.of(context).t('label_members')}: ${team.memberIds.length}',
          style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DesignTokens.textTertiaryDark),
        onTap: onTap,
      ),
    );
  }
}
