import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/admin_ekipler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_command_surface.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/providers/admin_teams_providers.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin → Ekipler: takım operasyon yüzeyi (Screen 13).
class AdminTeamsPage extends ConsumerWidget {
  const AdminTeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: EkiplerCommandSurface(
          onCreateTeam: () => _showCreateTeamDialog(context, ref),
          headerActions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              iconSize: AdminEkiplerTokens.rowTitleSize + 8,
              tooltip: l10n.t('action_add_team'),
              onPressed: () => _showCreateTeamDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showCreateTeamDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final consultants = await FirestoreService.consultantsStream().first;
    final managers = consultants
        .where((u) => AppRole.fromFirestoreRole(u.role).isManagerTier)
        .toList();
    var name = '';
    String? managerId = managers.isNotEmpty ? managers.first.uid : null;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppThemeExtension.of(context).surface,
              title: Text(l10n.t('action_add_team')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.t('label_team_name'),
                      ),
                      onChanged: (v) => name = v.trim(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    DropdownButtonFormField<String>(
                      initialValue: managerId,
                      decoration: InputDecoration(
                        labelText: l10n.t('label_manager'),
                      ),
                      items: managers
                          .map(
                            (u) => DropdownMenuItem(
                              value: u.uid,
                              child: Text(
                                u.name ?? u.email ?? u.uid,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => managerId = v),
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
                    if (name.isEmpty || managerId == null) return;
                    try {
                      await FirestoreService.createTeam(
                        name: name,
                        managerId: managerId!,
                      );
                      ref.invalidate(adminTeamsListProvider);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } catch (_) {
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
