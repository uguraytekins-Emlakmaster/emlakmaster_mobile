import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/admin_ekip_detay/presentation/admin_ekip_detay_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:flutter/material.dart';

class EkipDetayMemberRow extends StatelessWidget {
  const EkipDetayMemberRow({
    super.key,
    required this.user,
    required this.teamManagerId,
    required this.onTap,
    required this.onEdit,
    this.onKadro,
    this.onReports,
    this.onCommandCenter,
    this.onRemove,
    this.canEdit = true,
    this.canRemove = false,
  });

  final UserDoc user;
  final String teamManagerId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onKadro;
  final VoidCallback? onReports;
  final VoidCallback? onCommandCenter;
  final VoidCallback? onRemove;
  final bool canEdit;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final attention = kadroAttentionFor(user);
    final emphasize = attention.needsIntervention;
    final displayName = user.name ?? user.email ?? user.uid;
    final roleLabel = AppRole.fromFirestoreRole(user.role).label;
    final isManager = user.uid == teamManagerId && teamManagerId.isNotEmpty;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canEdit ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AdminEkipDetayTokens.horizontal,
              0,
              AdminEkipDetayTokens.horizontal,
              AdminEkipDetayTokens.moduleGap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(
              minHeight: AdminEkipDetayTokens.rowMinHeight,
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
                  radius: AdminEkipDetayTokens.rowAvatarSize / 2,
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
                                fontSize: AdminEkipDetayTokens.rowTitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          _StatusChip(
                            label: user.isActive ? 'Aktif' : 'Pasif',
                            color:
                                user.isActive ? ext.success : ext.textTertiary,
                          ),
                          if (isManager)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _StatusChip(
                                label: 'Yönetici',
                                color: ext.accent,
                              ),
                            ),
                          if (emphasize)
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
                        roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.92),
                          fontSize: AdminEkipDetayTokens.rowMetaSize,
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
                            fontSize: AdminEkipDetayTokens.rowChipSize,
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
                      case 'kadro':
                        onKadro?.call();
                      case 'reports':
                        onReports?.call();
                      case 'command':
                        onCommandCenter?.call();
                      case 'intervention':
                        if (canEdit) onEdit();
                      case 'remove':
                        onRemove?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Aç')),
                    if (canEdit)
                      const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    if (onKadro != null)
                      const PopupMenuItem(
                        value: 'kadro',
                        child: Text('Kadroya git'),
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
                    if (canEdit && emphasize)
                      const PopupMenuItem(
                        value: 'intervention',
                        child: Text('Müdahale detay'),
                      ),
                    if (canRemove && onRemove != null)
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Ekipten çıkar'),
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
          fontSize: AdminEkipDetayTokens.rowChipSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
