import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
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
        backgroundColor: AppThemeExtension.of(context).background,
        appBar: emlakAppBar(
          context,
          backgroundColor: AppThemeExtension.of(context).background,
          foregroundColor: AppThemeExtension.of(context).textPrimary,
          title: Text(AppLocalizations.of(context).t('title_admin_teams')),
        ),
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
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      appBar: emlakAppBar(
        context,
        backgroundColor: AppThemeExtension.of(context).background,
        foregroundColor: AppThemeExtension.of(context).textPrimary,
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
                      style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: DesignTokens.fontSizeSm),
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
            return Center(
              child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent),
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
                    Icon(Icons.groups_rounded, size: 64, color: AppThemeExtension.of(context).textTertiary),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      l10n.t('empty_teams_title'),
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                        fontSize: DesignTokens.fontSizeLg,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      l10n.t('empty_teams_subtitle'),
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textSecondary,
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
                        backgroundColor: AppThemeExtension.of(context).accent,
                        foregroundColor: AppThemeExtension.of(context).onAccentLight,
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
                  backgroundColor: AppThemeExtension.of(context).accent,
                  child: Icon(Icons.add_rounded, color: AppThemeExtension.of(context).onAccentLight),
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
              backgroundColor: AppThemeExtension.of(context).surface,
              title: Text(l10n.t('action_add_team'), style: TextStyle(color: AppThemeExtension.of(context).textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('label_team_name'),
                        labelStyle: TextStyle(color: AppThemeExtension.of(context).textSecondary),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeExtension.of(context).border)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeExtension.of(context).accent)),
                      ),
                      style: TextStyle(color: AppThemeExtension.of(context).textPrimary),
                      onChanged: (v) => name = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: managerId,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_manager'),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeExtension.of(context).border)),
                      ),
                      dropdownColor: AppThemeExtension.of(context).surface,
                      items: managers
                          .map((u) => DropdownMenuItem(
                                value: u.uid,
                                child: Text(
                                  u.name ?? u.email ?? u.uid,
                                  style: TextStyle(color: AppThemeExtension.of(context).textPrimary),
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
                  child: Text(l10n.t('cancel'), style: TextStyle(color: AppThemeExtension.of(context).textSecondary)),
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
                  style: FilledButton.styleFrom(backgroundColor: AppThemeExtension.of(context).accent),
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
      color: AppThemeExtension.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
        leading: CircleAvatar(
          backgroundColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.2),
          child: Icon(Icons.groups_rounded, color: AppThemeExtension.of(context).accent),
        ),
        title: Text(
          team.name,
          style: TextStyle(color: AppThemeExtension.of(context).textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${AppLocalizations.of(context).t('label_members')}: ${team.memberIds.length}',
          style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: DesignTokens.fontSizeSm),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppThemeExtension.of(context).textTertiary),
        onTap: onTap,
      ),
    );
  }
}
