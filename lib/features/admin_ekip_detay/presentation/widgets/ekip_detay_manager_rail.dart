import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/utils/ekip_detay_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_teams/presentation/providers/admin_teams_providers.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EkipDetayManagerRail extends ConsumerWidget {
  const EkipDetayManagerRail({
    super.key,
    required this.snapshot,
    required this.selectedManagerId,
    required this.onManagerChanged,
    required this.onSaveManager,
    required this.canManage,
  });

  final EkipDetaySnapshot snapshot;
  final String selectedManagerId;
  final ValueChanged<String?> onManagerChanged;
  final VoidCallback onSaveManager;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = snapshot.stats;
    final managersAsync = ref.watch(adminTeamManagersProvider);

    final alerts = <String>[];
    if (!stats.hasManager) alerts.add('Yönetici atanmamış');
    if (stats.isEmpty) alerts.add('Ekip kadrosu boş');
    if (stats.allMembersInactive && !stats.isEmpty) {
      alerts.add('Tüm üyeler pasif');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminEkipDetayTokens.horizontal,
        0,
        AdminEkipDetayTokens.horizontal,
        AdminEkipDetayTokens.moduleGap,
      ),
      child: ConsultantDashboardExecutiveSurface(
        ambientStrength: 0.62,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (alerts.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final a in alerts)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ext.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ext.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(
                            color: ext.warning,
                            fontSize: AdminCommandTokens.sectionSecondarySize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (!canManage)
                Text(
                  snapshot.managerName != null
                      ? '${snapshot.managerRoleLabel} · ${snapshot.managerName}'
                      : 'Yönetici atanmamış',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: AdminEkipDetayTokens.rowMetaSize,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                managersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (consultants) {
                    final managers = consultants
                        .where(
                          (u) =>
                              AppRole.fromFirestoreRole(u.role).isManagerTier,
                        )
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedManagerId.isEmpty
                              ? null
                              : selectedManagerId,
                          decoration: InputDecoration(
                            labelText: l10n.t('label_manager'),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: ext.border),
                            ),
                          ),
                          dropdownColor: ext.surface,
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
                          onChanged: onManagerChanged,
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: onSaveManager,
                            style: FilledButton.styleFrom(
                              backgroundColor: ext.accent,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(l10n.t('save')),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
