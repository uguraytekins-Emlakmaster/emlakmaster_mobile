import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin → Danışman Yönetimi: consultant-tier listesi, filtreler (rol/ekip), düzenleme ve yeni danışman bilgisi.
class AdminConsultantsPage extends ConsumerWidget {
  const AdminConsultantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleOrNullProvider) ?? AppRole.guest;
    if (!FeaturePermission.canManageConsultants(currentRole)) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: DesignTokens.backgroundDark,
        appBar: emlakAppBar(
          context,
          backgroundColor: DesignTokens.backgroundDark,
          foregroundColor: DesignTokens.textPrimaryDark,
          title: Text(l10n.t('title_admin_consultants')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.t('access_denied'),
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
        title: Text(l10n.t('title_admin_consultants')),
        actions: [
          if (FeaturePermission.canInviteAgents(currentRole))
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              onPressed: () => _showAddConsultantDialog(context, ref),
              tooltip: l10n.t('action_add_consultant'),
            ),
        ],
      ),
      body: _AdminConsultantsBody(canEditTeamRole: FeaturePermission.canManageTeams(currentRole)),
    );
  }

  static Future<void> _showAddConsultantDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    String fullName = '';
    String email = '';
    String inviteRole = AppRole.agent.id;
    String? teamId;
    final teams = await FirestoreService.teamsStream().first;
    if (teams.isNotEmpty) teamId = teams.first.id;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(l10n.t('action_add_consultant'), style: const TextStyle(color: DesignTokens.textPrimaryDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('full_name'),
                        labelStyle: const TextStyle(color: DesignTokens.textSecondaryDark),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.primary)),
                      ),
                      style: const TextStyle(color: DesignTokens.textPrimaryDark),
                      onChanged: (v) => fullName = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('label_email'),
                        labelStyle: const TextStyle(color: DesignTokens.textSecondaryDark),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.primary)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: DesignTokens.textPrimaryDark),
                      onChanged: (v) => email = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: inviteRole,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_role'),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                      ),
                      dropdownColor: DesignTokens.surfaceDark,
                      items: [AppRole.agent, AppRole.teamLead, AppRole.officeManager]
                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.label, style: const TextStyle(color: DesignTokens.textPrimaryDark))))
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
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                        ),
                        dropdownColor: DesignTokens.surfaceDark,
                        items: teams
                            .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(color: DesignTokens.textPrimaryDark))))
                            .toList(),
                        onChanged: (v) => setState(() => teamId = v),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space4),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space3),
                      decoration: BoxDecoration(
                        color: DesignTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(color: DesignTokens.borderDark),
                      ),
                      child: Text(
                        l10n.t('consultant_invite_info'),
                        style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
                      ),
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
                    if (email.trim().isEmpty) return;
                    final createdBy = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
                    if (createdBy.isEmpty) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.t('error_generic'))));
                      return;
                    }
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
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${l10n.t('error_generic')} $e')));
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

class _AdminConsultantsBody extends ConsumerStatefulWidget {
  const _AdminConsultantsBody({required this.canEditTeamRole});

  final bool canEditTeamRole;

  @override
  ConsumerState<_AdminConsultantsBody> createState() => _AdminConsultantsBodyState();
}

class _AdminConsultantsBodyState extends ConsumerState<_AdminConsultantsBody> {
  String _search = '';
  String? _filterRole;
  String? _filterTeamId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DesignTokens.space4, DesignTokens.space4, DesignTokens.space4, DesignTokens.space2),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.t('search_consultants'),
              hintStyle: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: DesignTokens.fontSizeSm),
              prefixIcon: const Icon(Icons.search_rounded, color: DesignTokens.textTertiaryDark),
              filled: true,
              fillColor: DesignTokens.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                borderSide: const BorderSide(color: DesignTokens.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                borderSide: const BorderSide(color: DesignTokens.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                borderSide: const BorderSide(color: DesignTokens.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3, vertical: DesignTokens.space2),
            ),
            style: const TextStyle(color: DesignTokens.textPrimaryDark, fontSize: DesignTokens.fontSizeSm),
            onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
          ),
        ),
        StreamBuilder<List<TeamDoc>>(
          stream: FirestoreService.teamsStream(),
          builder: (context, teamSnap) {
            final teams = teamSnap.data ?? [];
            return StreamBuilder<List<UserDoc>>(
              stream: FirestoreService.consultantsStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(snap.error.toString(), style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm), textAlign: TextAlign.center),
                          const SizedBox(height: DesignTokens.space3),
                          TextButton(onPressed: () => setState(() {}), child: Text(l10n.t('retry'))),
                        ],
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Expanded(child: Center(child: CircularProgressIndicator(color: DesignTokens.primary)));
                }
                var list = snap.data!;
                if (_search.isNotEmpty) {
                  list = list.where((u) {
                    final name = (u.name ?? '').toLowerCase();
                    final em = (u.email ?? '').toLowerCase();
                    return name.contains(_search) || em.contains(_search);
                  }).toList();
                }
                if (_filterRole != null && _filterRole!.isNotEmpty) {
                  list = list.where((u) => u.role == _filterRole).toList();
                }
                if (_filterTeamId != null && _filterTeamId!.isNotEmpty) {
                  list = list.where((u) => u.teamId == _filterTeamId).toList();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _filterRole,
                            isExpanded: true,
                            hint: Text(l10n.t('label_role'), style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 13)),
                            dropdownColor: DesignTokens.surfaceDark,
                            items: [
                              DropdownMenuItem<String?>(child: Text(l10n.t('filter_role_all'), style: const TextStyle(color: DesignTokens.textPrimaryDark))),
                              ...AppRole.values.where((r) => r.isManagerTier || r == AppRole.agent).map((r) => DropdownMenuItem(value: r.id, child: Text(r.label, style: const TextStyle(color: DesignTokens.textPrimaryDark)))),
                            ],
                            onChanged: (v) => setState(() => _filterRole = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space3),
                      if (teams.isNotEmpty)
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _filterTeamId,
                              isExpanded: true,
                              hint: Text(l10n.t('label_team'), style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: 13)),
                              dropdownColor: DesignTokens.surfaceDark,
                              items: [
                                DropdownMenuItem<String?>(child: Text(l10n.t('filter_team_all'), style: const TextStyle(color: DesignTokens.textPrimaryDark))),
                                ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(color: DesignTokens.textPrimaryDark), overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (v) => setState(() => _filterTeamId = v),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: DesignTokens.space2),
        Expanded(
          child: StreamBuilder<List<TeamDoc>>(
            stream: FirestoreService.teamsStream(),
            builder: (context, teamSnap) {
              final teams = teamSnap.data ?? [];
              final teamNames = {for (final t in teams) t.id: t.name};
              return StreamBuilder<List<UserDoc>>(
                stream: FirestoreService.consultantsStream(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  var list = snap.data!;
                  if (_search.isNotEmpty) {
                    list = list.where((u) {
                      final name = (u.name ?? '').toLowerCase();
                      final em = (u.email ?? '').toLowerCase();
                      return name.contains(_search) || em.contains(_search);
                    }).toList();
                  }
                  if (_filterRole != null && _filterRole!.isNotEmpty) list = list.where((u) => u.role == _filterRole).toList();
                  if (_filterTeamId != null && _filterTeamId!.isNotEmpty) list = list.where((u) => u.teamId == _filterTeamId).toList();

                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.t('empty_consultants'),
                        style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(DesignTokens.space4, 0, DesignTokens.space4, DesignTokens.space4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final u = list[index];
                      final teamName = u.teamId != null ? (teamNames[u.teamId] ?? u.teamId) : '—';
                      final roleLabel = AppRole.fromFirestoreRole(u.role).label;
                      return Card(
                        margin: const EdgeInsets.only(bottom: DesignTokens.space3),
                        color: DesignTokens.surfaceDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
                          leading: CircleAvatar(
                            backgroundColor: DesignTokens.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.person_rounded, color: DesignTokens.primary),
                          ),
                          title: Text(
                            u.name ?? u.email ?? u.uid,
                            style: const TextStyle(color: DesignTokens.textPrimaryDark, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${u.email ?? '—'} · $roleLabel · ${l10n.t('label_team')}: $teamName${u.isActive ? '' : ' · Pasif'}',
                            style: const TextStyle(color: DesignTokens.textSecondaryDark, fontSize: DesignTokens.fontSizeSm),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: widget.canEditTeamRole
                              ? IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: DesignTokens.primary, size: 20),
                                  onPressed: () => _showEditConsultantDialog(context, u, teams),
                                  tooltip: l10n.t('edit_consultant'),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showEditConsultantDialog(BuildContext context, UserDoc u, List<TeamDoc> teams) async {
    final l10n = AppLocalizations.of(context);
    String role = u.role;
    String? teamId = u.teamId;
    bool isActive = u.isActive;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(l10n.t('edit_consultant'), style: const TextStyle(color: DesignTokens.textPrimaryDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(u.name ?? u.email ?? u.uid, style: const TextStyle(color: DesignTokens.textPrimaryDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_role'),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                      ),
                      dropdownColor: DesignTokens.surfaceDark,
                      items: [AppRole.agent, AppRole.teamLead, AppRole.officeManager, AppRole.generalManager, AppRole.brokerOwner]
                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.label, style: const TextStyle(color: DesignTokens.textPrimaryDark))))
                          .toList(),
                      onChanged: (v) => setState(() => role = v ?? role),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String?>(
                      initialValue: teamId,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_team'),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderDark)),
                      ),
                      dropdownColor: DesignTokens.surfaceDark,
                      items: [
                        DropdownMenuItem<String?>(child: Text(l10n.t('filter_team_all'), style: const TextStyle(color: DesignTokens.textPrimaryDark))),
                        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(color: DesignTokens.textPrimaryDark)))),
                      ],
                      onChanged: (v) => setState(() => teamId = v),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Row(
                      children: [
                        Text(l10n.t('is_active'), style: const TextStyle(color: DesignTokens.textPrimaryDark)),
                        const SizedBox(width: DesignTokens.space2),
                        Switch(value: isActive, onChanged: (v) => setState(() => isActive = v), activeThumbColor: DesignTokens.primary),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    Text(
                      l10n.t('password_reset_info'),
                      style: const TextStyle(color: DesignTokens.textTertiaryDark, fontSize: DesignTokens.fontSizeXs),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.t('cancel'), style: const TextStyle(color: DesignTokens.textSecondaryDark))),
                FilledButton(
                  onPressed: () async {
                    try {
                      final managerId = teamId != null && teams.any((t) => t.id == teamId) ? teams.firstWhere((t) => t.id == teamId).managerId : null;
                      final oldTeamId = u.teamId;
                      if (oldTeamId != teamId) {
                        if (oldTeamId != null && oldTeamId.isNotEmpty) {
                          await FirestoreService.removeAgentFromTeam(u.uid, oldTeamId);
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
                          await FirestoreService.assignAgentToTeam(u.uid, newTeamId);
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
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${l10n.t('error_generic')} $e')));
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
