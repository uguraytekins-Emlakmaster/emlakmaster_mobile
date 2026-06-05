import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter/material.dart';

class KadroConsultantRow extends StatelessWidget {
  const KadroConsultantRow({
    super.key,
    required this.user,
    required this.teamName,
    required this.onTap,
    required this.onEdit,
    this.onTeamDetail,
    this.onReports,
    this.onCommandCenter,
    this.canEdit = true,
  });

  final UserDoc user;
  final String? teamName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onTeamDetail;
  final VoidCallback? onReports;
  final VoidCallback? onCommandCenter;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final attention = kadroAttentionFor(user);
    final emphasize = attention.needsIntervention;
    final displayName = user.name ?? user.email ?? user.uid;
    final roleLabel = AppRole.fromFirestoreRole(user.role).label;
    final teamLabel = teamName ?? 'Atanmamış';

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminKadroTokens.horizontal,
              0,
              AdminKadroTokens.horizontal,
              AdminKadroTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminKadroTokens.rowMinHeight,
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
                  radius: AdminKadroTokens.rowAvatarSize / 2,
                  backgroundColor: ext.accent.withValues(alpha: 0.16),
                  child: Text(
                    _initials(displayName),
                    style: TextStyle(
                      color: ext.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textPrimary,
                                fontSize: AdminKadroTokens.rowTitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          _StatusChip(
                            label: user.isActive ? 'Aktif' : 'Pasif',
                            color: user.isActive ? ext.success : ext.textTertiary,
                          ),
                          if (attention == KadroConsultantAttention.unassignedTeam)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _StatusChip(
                                label: 'Ekip yok',
                                color: ext.warning,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$roleLabel · $teamLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminKadroTokens.rowMetaSize,
                          height: 1.15,
                        ),
                      ),
                      if (user.email != null && user.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: AdminKadroTokens.rowChipSize,
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
                    switch (value) {
                      case 'open':
                        onTap();
                      case 'edit':
                        if (canEdit) onEdit();
                      case 'team':
                        onTeamDetail?.call();
                      case 'reports':
                        onReports?.call();
                      case 'command':
                        onCommandCenter?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Aç'),
                    ),
                    if (canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Düzenle'),
                      ),
                    if (onTeamDetail != null)
                      const PopupMenuItem(
                        value: 'team',
                        child: Text('Takım detay'),
                      ),
                    if (onReports != null)
                      const PopupMenuItem(
                        value: 'reports',
                        child: Text('Raporlar'),
                      ),
                    if (onCommandCenter != null)
                      const PopupMenuItem(
                        value: 'command',
                        child: Text('Çağrı merkezi'),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
          fontSize: AdminKadroTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
