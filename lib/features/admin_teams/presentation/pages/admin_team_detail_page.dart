import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter/material.dart';

/// Ekip detay: ad, manager seçimi, üye listesi, üye ekle / ekipten çıkar.
class AdminTeamDetailPage extends StatefulWidget {
  const AdminTeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  State<AdminTeamDetailPage> createState() => _AdminTeamDetailPageState();
}

class _AdminTeamDetailPageState extends State<AdminTeamDetailPage> {
  String? _selectedManagerId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: emlakAppBar(
        context,
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        title: Text(l10n.t('title_team_detail')),
      ),
      body: StreamBuilder<TeamDoc?>(
        stream: FirestoreService.teamDocStream(widget.teamId),
        builder: (context, teamSnap) {
          if (!teamSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: DesignTokens.primary),
            );
          }
          final team = teamSnap.data;
          if (team == null) {
            return Center(
              child: Text(
                l10n.t('team_not_found'),
                style: const TextStyle(color: DesignTokens.textSecondaryDark),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TeamInfoCard(
                  team: team,
                  selectedManagerId: _selectedManagerId ?? team.managerId,
                  onManagerChanged: (id) => setState(() => _selectedManagerId = id),
                  onSaveManager: () => _saveManager(team),
                ),
                const SizedBox(height: DesignTokens.space5),
                _MembersCard(teamId: team.id, memberIds: team.memberIds),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveManager(TeamDoc team) async {
    final managerId = _selectedManagerId ?? team.managerId;
    if (managerId.isEmpty) return;
    try {
      await FirestoreService.updateTeamManager(team.id, managerId);
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
          SnackBar(content: Text('${AppLocalizations.of(context).t('error_generic')} $e')),
        );
      }
    }
  }
}

class _TeamInfoCard extends StatelessWidget {
  const _TeamInfoCard({
    required this.team,
    required this.selectedManagerId,
    required this.onManagerChanged,
    required this.onSaveManager,
  });

  final TeamDoc team;
  final String selectedManagerId;
  final ValueChanged<String?> onManagerChanged;
  final VoidCallback onSaveManager;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: DesignTokens.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name,
              style: const TextStyle(
                color: DesignTokens.textPrimaryDark,
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            StreamBuilder<List<UserDoc>>(
              stream: FirestoreService.consultantsStream(),
              builder: (context, snap) {
                final managers = (snap.data ?? [])
                    .where((u) => AppRole.fromFirestoreRole(u.role).isManagerTier)
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: selectedManagerId.isEmpty ? null : selectedManagerId,
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
                  onChanged: onManagerChanged,
                );
              },
            ),
            const SizedBox(height: DesignTokens.space3),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSaveManager,
                style: FilledButton.styleFrom(backgroundColor: DesignTokens.primary),
                child: Text(l10n.t('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.teamId, required this.memberIds});

  final String teamId;
  final List<String> memberIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: DesignTokens.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.t('label_members'),
                  style: const TextStyle(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddMemberDialog(context, teamId),
                  icon: const Icon(Icons.person_add_rounded, size: 18, color: DesignTokens.primary),
                  label: Text(l10n.t('action_add_member'), style: const TextStyle(color: DesignTokens.primary)),
                ),
              ],
            ),
            if (memberIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
                child: Text(
                  l10n.t('empty_team_members'),
                  style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
                ),
              )
            else
              ...memberIds.map((uid) => _MemberTile(teamId: teamId, uid: uid)),
          ],
        ),
      ),
    );
  }

  static Future<void> _showAddMemberDialog(BuildContext context, String teamId) async {
    final l10n = AppLocalizations.of(context);
    final consultants = await FirestoreService.consultantsStream().first;
    final teamList = await FirestoreService.teamsStream().first;
    final currentTeam = teamList.where((t) => t.id == teamId).toList();
    final currentTeamDoc = currentTeam.isNotEmpty ? currentTeam.first : null;
    final currentMemberIds = currentTeamDoc?.memberIds ?? [];
    final available = consultants.where((u) => !currentMemberIds.contains(u.uid)).toList();

    if (!context.mounted) return;
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
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(l10n.t('action_add_member'), style: const TextStyle(color: DesignTokens.textPrimaryDark)),
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
                        style: const TextStyle(color: DesignTokens.textPrimaryDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        u.email ?? u.role,
                        style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      activeColor: DesignTokens.primary,
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
                  child: Text(l10n.t('cancel'), style: const TextStyle(color: DesignTokens.textSecondaryDark)),
                ),
                FilledButton(
                  onPressed: () async {
                    for (final uid in selected) {
                      await FirestoreService.assignAgentToTeam(uid, teamId);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.teamId, required this.uid});

  final String teamId;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<UserDoc?>(
      future: UserRepository.getUserDoc(uid),
      builder: (context, snap) {
        final user = snap.data;
        final name = user?.name ?? user?.email ?? uid;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
            child: const Icon(Icons.person_rounded, color: DesignTokens.primary, size: 20),
          ),
          title: Text(
            name,
            style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: DesignTokens.fontSizeSm),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: user?.email != null
              ? Text(
                  user!.email!,
                  style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: DesignTokens.surfaceDark,
                  title: Text(l10n.t('action_remove_from_team'), style: const TextStyle(color: DesignTokens.textPrimaryDark)),
                  content: Text(
                    l10n.t('confirm_remove_from_team'),
                    style: const TextStyle(color: DesignTokens.textSecondaryDark),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.t('cancel'), style: const TextStyle(color: DesignTokens.textSecondaryDark)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(backgroundColor: DesignTokens.danger),
                      child: Text(l10n.t('action_remove_from_team')),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirestoreService.removeAgentFromTeam(uid, teamId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.t('member_removed')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.t('action_remove_from_team'),
              style: const TextStyle(color: DesignTokens.danger, fontSize: DesignTokens.fontSizeSm),
            ),
          ),
        );
      },
    );
  }
}
