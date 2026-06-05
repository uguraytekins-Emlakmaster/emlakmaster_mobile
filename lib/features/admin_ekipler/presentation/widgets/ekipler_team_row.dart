import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/admin_ekipler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';

class EkiplerTeamRow extends StatelessWidget {
  const EkiplerTeamRow({
    super.key,
    required this.viewModel,
    required this.detailed,
    required this.onTap,
    required this.onKadro,
    required this.onReports,
    this.onAssign,
    this.onCommandCenter,
    this.onWarRoom,
  });

  final EkiplerTeamViewModel viewModel;
  final bool detailed;
  final VoidCallback onTap;
  final VoidCallback onKadro;
  final VoidCallback onReports;
  final VoidCallback? onAssign;
  final VoidCallback? onCommandCenter;
  final VoidCallback? onWarRoom;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final stats = viewModel.stats;
    final emphasize = stats.needsIntervention;
    final managerLine = viewModel.managerName != null
        ? '${viewModel.managerRoleLabel} · ${viewModel.managerName}'
        : 'Yönetici atanmamış';

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminEkiplerTokens.horizontal,
              0,
              AdminEkiplerTokens.horizontal,
              AdminEkiplerTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminEkiplerTokens.rowMinHeight,
            ),
            decoration: BoxDecoration(
              color: emphasize
                  ? ext.warning.withValues(alpha: 0.07)
                  : ext.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: emphasize
                    ? ext.warning.withValues(alpha: 0.28)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: AdminEkiplerTokens.rowAvatarSize / 2,
                  backgroundColor: ext.accent.withValues(alpha: 0.16),
                  child: Icon(
                    Icons.groups_rounded,
                    color: ext.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              viewModel.team.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: AdminEkiplerTokens.rowTitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          _StatusChip(
                            label: stats.isEmpty ? 'Boş' : 'Aktif ${stats.activeMembers}',
                            color: stats.isEmpty
                                ? ext.textTertiary
                                : ext.success,
                          ),
                          if (stats.needsIntervention)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _StatusChip(
                                label: 'Müdahale',
                                color: ext.warning,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$managerLine · ${stats.totalMembers} üye',
                        maxLines: detailed ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminEkiplerTokens.rowMetaSize,
                          height: 1.15,
                        ),
                      ),
                      if (detailed) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Aktif ${stats.activeMembers} · Pasif ${stats.inactiveMembers}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: AdminEkiplerTokens.rowChipSize,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: ext.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onSelected: (value) {
                    // PopupRoute kapanışını tamamlamak için navigasyonu bir kare ertele.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      switch (value) {
                      case 'open':
                        onTap();
                      case 'kadro':
                        onKadro();
                      case 'reports':
                        onReports();
                      case 'assign':
                        onAssign?.call();
                      case 'intervention':
                        onTap();
                      case 'command':
                        onCommandCenter?.call();
                      case 'war':
                        onWarRoom?.call();
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Aç')),
                    const PopupMenuItem(
                      value: 'kadro',
                      child: Text('Kadroyu gör'),
                    ),
                    const PopupMenuItem(
                      value: 'reports',
                      child: Text('Raporlar'),
                    ),
                    if (stats.needsIntervention)
                      const PopupMenuItem(
                        value: 'intervention',
                        child: Text('Müdahale'),
                      ),
                    if (onAssign != null)
                      const PopupMenuItem(
                        value: 'assign',
                        child: Text('Takıma danışman ata'),
                      ),
                    if (onCommandCenter != null)
                      const PopupMenuItem(
                        value: 'command',
                        child: Text('Çağrı merkezi'),
                      ),
                    if (onWarRoom != null)
                      const PopupMenuItem(
                        value: 'war',
                        child: Text('Savaş odası'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EkiplerUnassignedRow extends StatelessWidget {
  const EkiplerUnassignedRow({
    super.key,
    required this.user,
    required this.onKadro,
  });

  final UserDoc user;
  final VoidCallback onKadro;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final name = user.name ?? user.email ?? user.uid;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onKadro,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminEkiplerTokens.horizontal,
              0,
              AdminEkiplerTokens.horizontal,
              AdminEkiplerTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminEkiplerTokens.rowMinHeight - 8,
            ),
            decoration: BoxDecoration(
              color: ext.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ext.warning.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textPrimary,
                          fontSize: AdminEkiplerTokens.rowTitleSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Ekip atanmamış',
                        style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: AdminEkiplerTokens.rowMetaSize,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onKadro, child: const Text('Kadro')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AdminEkiplerTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
